#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ACTIVE_SLOT_PARAM="${ACTIVE_SLOT_PARAM:-/smartlogix/deploy/active_slot}"
ROLLOUT_STATE_PARAM="${ROLLOUT_STATE_PARAM:-/smartlogix/deploy/canary_rollout_state}"
ROLLOUT_INTERVAL_SECONDS="${ROLLOUT_INTERVAL_SECONDS:-17280}" # 24h / 5 intervals
CANARY_REQUESTS="${CANARY_REQUESTS:-20}"
CANARY_MAX_FAILED_REQUESTS="${CANARY_MAX_FAILED_REQUESTS:-1}"

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: ${cmd}" >&2
    exit 1
  fi
}

slot_to_dir() {
  case "$1" in
    main) echo "environments/main" ;;
    canary) echo "environments/canary" ;;
    *)
      echo "Unsupported slot: $1" >&2
      exit 1
      ;;
  esac
}

opposite_slot() {
  case "$1" in
    main) echo "canary" ;;
    canary) echo "main" ;;
    *)
      echo "Unsupported slot: $1" >&2
      exit 1
      ;;
  esac
}

get_active_slot() {
  if aws ssm get-parameter --name "$ACTIVE_SLOT_PARAM" --query 'Parameter.Value' --output text >/dev/null 2>&1; then
    aws ssm get-parameter --name "$ACTIVE_SLOT_PARAM" --query 'Parameter.Value' --output text
  else
    echo "main"
  fi
}

put_active_slot() {
  local slot="$1"
  aws ssm put-parameter \
    --name "$ACTIVE_SLOT_PARAM" \
    --type String \
    --overwrite \
    --value "$slot" >/dev/null
}

get_rollout_state() {
  aws ssm get-parameter --name "$ROLLOUT_STATE_PARAM" --query 'Parameter.Value' --output text 2>/dev/null || true
}

put_rollout_state() {
  local value="$1"
  aws ssm put-parameter \
    --name "$ROLLOUT_STATE_PARAM" \
    --type String \
    --overwrite \
    --value "$value" >/dev/null
}

delete_rollout_state() {
  aws ssm delete-parameter --name "$ROLLOUT_STATE_PARAM" >/dev/null 2>&1 || true
}

run_terragrunt() {
  local slot="$1"
  shift
  local env_dir
  env_dir="$(slot_to_dir "$slot")"
  (
    cd "${ROOT_DIR}/${env_dir}"
    terragrunt init -reconfigure -input=false >/dev/null
    terragrunt "$@" -input=false
  )
}

slot_exists() {
  local slot="$1"
  local env_dir
  env_dir="$(slot_to_dir "$slot")"
  (cd "${ROOT_DIR}/${env_dir}" && terragrunt output -json >/dev/null 2>&1)
}

slot_output_json() {
  local slot="$1"
  local env_dir
  env_dir="$(slot_to_dir "$slot")"
  (cd "${ROOT_DIR}/${env_dir}" && terragrunt output -json)
}

slot_alb_dns() {
  slot_output_json "$1" | jq -r '.alb_dns_name.value'
}

slot_alb_zone_id() {
  slot_output_json "$1" | jq -r '.alb_zone_id.value'
}

slot_listener_arn() {
  slot_output_json "$1" | jq -r '.http_listener_arn.value'
}

slot_target_group_arn() {
  slot_output_json "$1" | jq -r '.target_group_kong_arn.value'
}

ensure_slot_exists() {
  local slot="$1"
  if slot_exists "$slot"; then
    return 0
  fi

  echo "Slot ${slot} has no state yet. Creating baseline stack..."
  run_terragrunt "$slot" apply -auto-approve -lock-timeout=5m >/dev/null
}

set_alb_listener_weights() {
  local listener_arn="$1"
  local primary_tg_arn="$2"
  local canary_tg_arn="$3"
  local canary_weight="$4"
  local primary_weight=$((100 - canary_weight))

  local actions_json
  actions_json="$(jq -cn \
    --arg primary_tg "$primary_tg_arn" \
    --arg canary_tg "$canary_tg_arn" \
    --argjson primary_weight "$primary_weight" \
    --argjson canary_weight "$canary_weight" \
    '[{
      Type: "forward",
      ForwardConfig: {
        TargetGroups: [
          { TargetGroupArn: $primary_tg, Weight: $primary_weight },
          { TargetGroupArn: $canary_tg, Weight: $canary_weight }
        ],
        TargetGroupStickinessConfig: { Enabled: false }
      }
    }]')"

  aws elbv2 modify-listener \
    --listener-arn "$listener_arn" \
    --default-actions "$actions_json" >/dev/null
}

set_slot_listener_full_weight() {
  local slot="$1"
  local listener_arn tg_arn actions_json
  listener_arn="$(slot_listener_arn "$slot")"
  tg_arn="$(slot_target_group_arn "$slot")"

  actions_json="$(jq -cn --arg tg "$tg_arn" '[{Type:"forward", TargetGroupArn:$tg}]')"
  aws elbv2 modify-listener \
    --listener-arn "$listener_arn" \
    --default-actions "$actions_json" >/dev/null
}

switch_primary_dns_to_slot_if_configured() {
  if [[ -z "${ROUTE53_HOSTED_ZONE_ID:-}" || -z "${APP_FQDN:-}" ]]; then
    echo "ROUTE53_HOSTED_ZONE_ID/APP_FQDN not configured. Skipping final DNS switch."
    return 0
  fi

  local slot="$1"
  local dns zone
  dns="$(slot_alb_dns "$slot")"
  zone="$(slot_alb_zone_id "$slot")"

  cat >"${ROOT_DIR}/route53-cutover.json" <<EOF
{
  "Comment": "Cutover primary endpoint to ${slot}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${APP_FQDN}",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "${zone}",
          "DNSName": "${dns}",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
EOF

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ROUTE53_HOSTED_ZONE_ID" \
    --change-batch "file://${ROOT_DIR}/route53-cutover.json" >/dev/null
  rm -f "${ROOT_DIR}/route53-cutover.json"
}

health_check_slot() {
  local slot="$1"
  local dns
  dns="$(slot_alb_dns "$slot")"
  local failed=0

  for _ in $(seq 1 "$CANARY_REQUESTS"); do
    local code
    code="$(curl -sS -o /dev/null -w "%{http_code}" "http://${dns}/status" || true)"
    if [[ "$code" != "200" ]]; then
      failed=$((failed + 1))
    fi
    sleep 3
  done

  echo "Canary health check failures: ${failed}/${CANARY_REQUESTS}"
  [[ "$failed" -le "$CANARY_MAX_FAILED_REQUESTS" ]]
}

start_rollout() {
  local active_slot inactive_slot ingress_listener active_tg inactive_tg now state
  active_slot="$(get_active_slot)"
  inactive_slot="$(opposite_slot "$active_slot")"

  ensure_slot_exists "$active_slot"
  run_terragrunt "$inactive_slot" apply -auto-approve -lock-timeout=5m >/dev/null

  ingress_listener="$(slot_listener_arn "$active_slot")"
  active_tg="$(slot_target_group_arn "$active_slot")"
  inactive_tg="$(slot_target_group_arn "$inactive_slot")"

  set_alb_listener_weights "$ingress_listener" "$active_tg" "$inactive_tg" 5

  now="$(date +%s)"
  state="$(jq -n \
    --arg active "$active_slot" \
    --arg inactive "$inactive_slot" \
    --arg listener "$ingress_listener" \
    --arg active_tg "$active_tg" \
    --arg inactive_tg "$inactive_tg" \
    --argjson step_index 0 \
    --argjson last_shift_epoch "$now" \
    '{
      active_slot:$active,
      inactive_slot:$inactive,
      ingress_listener_arn:$listener,
      active_target_group_arn:$active_tg,
      inactive_target_group_arn:$inactive_tg,
      step_index:$step_index,
      last_shift_epoch:$last_shift_epoch
    }')"
  put_rollout_state "$state"
  echo "Canary rollout started via ALB listener weights: ${active_slot} -> ${inactive_slot} at 5%"
}

advance_rollout() {
  local state
  state="$(get_rollout_state)"
  if [[ -z "$state" ]]; then
    echo "No canary rollout in progress."
    return 0
  fi

  local active_slot inactive_slot ingress_listener active_tg inactive_tg step_index last_shift now elapsed
  active_slot="$(jq -r '.active_slot' <<<"$state")"
  inactive_slot="$(jq -r '.inactive_slot' <<<"$state")"
  ingress_listener="$(jq -r '.ingress_listener_arn' <<<"$state")"
  active_tg="$(jq -r '.active_target_group_arn' <<<"$state")"
  inactive_tg="$(jq -r '.inactive_target_group_arn' <<<"$state")"
  step_index="$(jq -r '.step_index' <<<"$state")"
  last_shift="$(jq -r '.last_shift_epoch' <<<"$state")"

  now="$(date +%s)"
  elapsed=$((now - last_shift))
  if [[ "$elapsed" -lt "$ROLLOUT_INTERVAL_SECONDS" ]]; then
    echo "Waiting next interval. Elapsed ${elapsed}s of ${ROLLOUT_INTERVAL_SECONDS}s."
    return 0
  fi

  if ! health_check_slot "$inactive_slot"; then
    echo "Canary health check failed. Rolling back traffic to ${active_slot} via ALB."
    set_alb_listener_weights "$ingress_listener" "$active_tg" "$inactive_tg" 0
    delete_rollout_state
    exit 1
  fi

  local weights=(5 10 25 50 75 100)
  local next_step=$((step_index + 1))
  local max_index=$(( ${#weights[@]} - 1 ))
  if [[ "$next_step" -gt "$max_index" ]]; then
    echo "Rollout state is already completed; cleaning state parameter."
    delete_rollout_state
    return 0
  fi

  local next_weight="${weights[$next_step]}"
  set_alb_listener_weights "$ingress_listener" "$active_tg" "$inactive_tg" "$next_weight"
  echo "Traffic shifted via ALB listener to ${inactive_slot}: ${next_weight}%"

  if [[ "$next_step" -eq "$max_index" ]]; then
    echo "Canary reached 100%. Finalizing cutover and destroying previous active slot: ${active_slot}"
    set_slot_listener_full_weight "$inactive_slot"
    switch_primary_dns_to_slot_if_configured "$inactive_slot"
    run_terragrunt "$active_slot" destroy -auto-approve -lock-timeout=5m >/dev/null
    put_active_slot "$inactive_slot"
    delete_rollout_state
    echo "Promotion completed. Active slot is now ${inactive_slot}."
    return 0
  fi

  local updated
  updated="$(jq \
    --argjson step_index "$next_step" \
    --argjson last_shift_epoch "$now" \
    '.step_index = $step_index | .last_shift_epoch = $last_shift_epoch' <<<"$state")"
  put_rollout_state "$updated"
}

abort_rollout() {
  echo "Aborting canary rollout and restoring main as sole active slot."

  ensure_slot_exists "main"
  set_slot_listener_full_weight "main"
  switch_primary_dns_to_slot_if_configured "main"
  put_active_slot "main"
  delete_rollout_state

  if slot_exists "canary"; then
    echo "Destroying canary slot."
    run_terragrunt "canary" destroy -auto-approve -lock-timeout=5m >/dev/null
  else
    echo "Canary slot does not exist. Nothing to destroy."
  fi

  echo "Abort completed. All traffic is served by main."
}

usage() {
  cat <<EOF
Usage: $0 <start|advance|abort>
EOF
}

main() {
  require_cmd aws
  require_cmd terragrunt
  require_cmd jq
  require_cmd curl

  if [[ "$#" -ne 1 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    start) start_rollout ;;
    advance) advance_rollout ;;
    abort) abort_rollout ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
