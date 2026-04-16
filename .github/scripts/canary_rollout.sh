#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRANSVERSAL_DIR="environments/transversal"
ACTIVE_SLOT_PARAM="${ACTIVE_SLOT_PARAM:-/smartlogix/deploy/active_slot}"
ROLLOUT_STATE_PARAM="${ROLLOUT_STATE_PARAM:-/smartlogix/deploy/canary_rollout_state}"
ROLLOUT_INTERVAL_SECONDS="${ROLLOUT_INTERVAL_SECONDS:-300}" # 5m between shifts (~25-30m full rollout)
CANARY_MIN_HEALTHY_TARGETS="${CANARY_MIN_HEALTHY_TARGETS:-1}"
CANARY_HEALTH_RETRIES="${CANARY_HEALTH_RETRIES:-6}"
CANARY_HEALTH_RETRY_INTERVAL_SECONDS="${CANARY_HEALTH_RETRY_INTERVAL_SECONDS:-20}"
REQUIRED_TRANSVERSAL_OUTPUTS=(
  "vpc_id"
  "private_subnets"
  "public_subnets"
  "vpc_cidr_block"
  "alb_security_group_id"
  "http_listener_arn"
  "alb_dns_name"
  "alb_zone_id"
)
REQUIRED_SLOT_OUTPUTS=(
  "target_group_kong_arn"
)

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

run_terragrunt_transversal() {
  (
    cd "${ROOT_DIR}/${TRANSVERSAL_DIR}"
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

transversal_exists() {
  (cd "${ROOT_DIR}/${TRANSVERSAL_DIR}" && terragrunt output -json >/dev/null 2>&1)
}

slot_output_json() {
  local slot="$1"
  local env_dir
  env_dir="$(slot_to_dir "$slot")"
  (cd "${ROOT_DIR}/${env_dir}" && terragrunt output -json)
}

transversal_output_json() {
  (cd "${ROOT_DIR}/${TRANSVERSAL_DIR}" && terragrunt output -json)
}

outputs_have_required_keys() {
  local outputs_json="$1"
  shift
  local required_keys=("$@")

  local key
  for key in "${required_keys[@]}"; do
    if ! jq -e --arg k "$key" '
      has($k) and
      .[$k] != null and
      .[$k].value != null and
      (
        (.[$k].value | type) != "string" or
        (
          (.[$k].value | length) > 0 and
          .[$k].value != "null"
        )
      ) and
      (
        (.[$k].value | type) != "array" or
        (.[$k].value | length) > 0
      )
    ' >/dev/null <<<"$outputs_json"; then
      echo "Missing or empty required output: ${key}" >&2
      return 1
    fi
  done
}

transversal_has_required_outputs() {
  local outputs_json="$1"
  outputs_have_required_keys "$outputs_json" "${REQUIRED_TRANSVERSAL_OUTPUTS[@]}"
}

slot_has_required_outputs() {
  local outputs_json="$1"
  outputs_have_required_keys "$outputs_json" "${REQUIRED_SLOT_OUTPUTS[@]}"
}

is_valid_arn() {
  local value="$1"
  [[ -n "$value" && "$value" != "null" && "$value" =~ ^arn:aws[a-zA-Z-]*:[a-z0-9-]+:[a-z0-9-]*:[0-9]*:.+ ]]
}

require_valid_arn() {
  local label="$1"
  local value="$2"
  if ! is_valid_arn "$value"; then
    echo "Invalid ${label}: '${value}'. The rollout cannot continue with an empty or malformed ARN." >&2
    exit 1
  fi
}

ingress_listener_arn() {
  transversal_output_json | jq -r '.http_listener_arn.value'
}

ingress_alb_dns() {
  transversal_output_json | jq -r '.alb_dns_name.value'
}

ingress_alb_zone_id() {
  transversal_output_json | jq -r '.alb_zone_id.value'
}

slot_target_group_arn() {
  slot_output_json "$1" | jq -r '.target_group_kong_arn.value'
}

ensure_slot_ready() {
  local slot="$1"
  local outputs_json

  if slot_exists "$slot"; then
    echo "Reconciling slot ${slot} stack to current configuration..."
  else
    echo "Slot ${slot} has no state yet. Creating baseline stack..."
  fi

  run_terragrunt "$slot" apply -auto-approve -lock-timeout=5m >/dev/null

  outputs_json="$(slot_output_json "$slot")"
  if ! slot_has_required_outputs "$outputs_json"; then
    echo "Slot ${slot} outputs are still incomplete after apply. Aborting rollout." >&2
    exit 1
  fi
}

ensure_transversal_exists() {
  local outputs_json
  if transversal_exists; then
    echo "Reconciling transversal stack to current configuration..."
  else
    echo "Transversal stack has no state yet. Creating shared networking and ingress..."
  fi

  run_terragrunt_transversal apply -auto-approve -lock-timeout=5m >/dev/null

  outputs_json="$(transversal_output_json)"
  if ! transversal_has_required_outputs "$outputs_json"; then
    echo "Transversal outputs are still incomplete after apply. Aborting rollout." >&2
    exit 1
  fi
}

set_alb_listener_weights() {
  local listener_arn="$1"
  local primary_tg_arn="$2"
  local canary_tg_arn="$3"
  local canary_weight="$4"
  local primary_weight=$((100 - canary_weight))

  require_valid_arn "listener ARN" "$listener_arn"
  require_valid_arn "primary target group ARN" "$primary_tg_arn"
  require_valid_arn "canary target group ARN" "$canary_tg_arn"

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

set_listener_single_target() {
  local listener_arn="$1"
  local tg_arn="$2"
  local actions_json

  require_valid_arn "listener ARN" "$listener_arn"
  require_valid_arn "target group ARN" "$tg_arn"

  actions_json="$(jq -cn --arg tg "$tg_arn" '[{Type:"forward", TargetGroupArn:$tg}]')"

  aws elbv2 modify-listener \
    --listener-arn "$listener_arn" \
    --default-actions "$actions_json" >/dev/null
}

switch_primary_dns_to_ingress_if_configured() {
  if [[ -z "${ROUTE53_HOSTED_ZONE_ID:-}" || -z "${APP_FQDN:-}" ]]; then
    echo "ROUTE53_HOSTED_ZONE_ID/APP_FQDN not configured. Skipping DNS upsert."
    return 0
  fi

  local dns zone
  dns="$(ingress_alb_dns)"
  zone="$(ingress_alb_zone_id)"

  cat >"${ROOT_DIR}/route53-cutover.json" <<EOF
{
  "Comment": "Point primary endpoint to shared ingress ALB",
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
  local tg_arn
  tg_arn="$(slot_target_group_arn "$slot")"
  require_valid_arn "target group ARN for slot ${slot}" "$tg_arn"

  local states
  states="$(aws elbv2 describe-target-health \
    --target-group-arn "$tg_arn" \
    --query 'TargetHealthDescriptions[].TargetHealth.State' \
    --output text 2>/dev/null || true)"

  if [[ -z "$states" ]]; then
    echo "No target health data available for slot ${slot}."
    return 1
  fi

  local healthy total
  total="$(awk '{print NF}' <<<"$states")"
  healthy="$(tr '\t' '\n' <<<"$states" | awk '$1=="healthy"{c++} END{print c+0}')"

  echo "Slot ${slot} target health: healthy=${healthy}, total=${total}"
  [[ "$healthy" -ge "$CANARY_MIN_HEALTHY_TARGETS" ]]
}

wait_for_slot_health() {
  local slot="$1"
  local attempt=1

  while [[ "$attempt" -le "$CANARY_HEALTH_RETRIES" ]]; do
    if health_check_slot "$slot"; then
      return 0
    fi

    if [[ "$attempt" -lt "$CANARY_HEALTH_RETRIES" ]]; then
      echo "Canary health check attempt ${attempt}/${CANARY_HEALTH_RETRIES} failed. Retrying in ${CANARY_HEALTH_RETRY_INTERVAL_SECONDS}s..."
      sleep "$CANARY_HEALTH_RETRY_INTERVAL_SECONDS"
    fi

    attempt=$((attempt + 1))
  done

  return 1
}

start_rollout() {
  local active_slot inactive_slot ingress_listener active_tg inactive_tg now state
  ensure_transversal_exists

  active_slot="$(get_active_slot)"
  inactive_slot="$(opposite_slot "$active_slot")"

  ensure_slot_ready "$active_slot"
  ensure_slot_ready "$inactive_slot"

  ingress_listener="$(ingress_listener_arn)"
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
  switch_primary_dns_to_ingress_if_configured
  echo "Canary rollout started: ${active_slot} -> ${inactive_slot} at 5%"
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
  step_index="$(jq -r '.step_index' <<<"$state")"
  last_shift="$(jq -r '.last_shift_epoch' <<<"$state")"

  now="$(date +%s)"
  elapsed=$((now - last_shift))
  if [[ "$elapsed" -lt "$ROLLOUT_INTERVAL_SECONDS" ]]; then
    echo "Waiting next interval. Elapsed ${elapsed}s of ${ROLLOUT_INTERVAL_SECONDS}s."
    return 0
  fi

  ensure_slot_ready "$inactive_slot"

  ingress_listener="$(ingress_listener_arn)"
  active_tg="$(slot_target_group_arn "$active_slot")"
  inactive_tg="$(slot_target_group_arn "$inactive_slot")"

  require_valid_arn "rollout listener ARN" "$ingress_listener"
  require_valid_arn "rollout active target group ARN" "$active_tg"
  require_valid_arn "rollout inactive target group ARN" "$inactive_tg"

  if ! wait_for_slot_health "$inactive_slot"; then
    echo "Canary health check failed. Rolling back traffic to ${active_slot}."
    set_listener_single_target "$ingress_listener" "$active_tg"
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
  echo "Traffic shifted to ${inactive_slot}: ${next_weight}%"

  if [[ "$next_step" -eq "$max_index" ]]; then
    echo "Canary reached 100%. Destroying previous active slot: ${active_slot}"
    set_listener_single_target "$ingress_listener" "$inactive_tg"
    run_terragrunt "$active_slot" destroy -auto-approve -lock-timeout=5m >/dev/null
    put_active_slot "$inactive_slot"
    delete_rollout_state
    echo "Promotion completed. Active slot is now ${inactive_slot}."
    return 0
  fi

  local updated
  updated="$(jq \
    --arg listener "$ingress_listener" \
    --arg active_tg "$active_tg" \
    --arg inactive_tg "$inactive_tg" \
    --argjson step_index "$next_step" \
    --argjson last_shift_epoch "$now" \
    '.ingress_listener_arn = $listener |
     .active_target_group_arn = $active_tg |
     .inactive_target_group_arn = $inactive_tg |
     .step_index = $step_index |
     .last_shift_epoch = $last_shift_epoch' <<<"$state")"
  put_rollout_state "$updated"
}

abort_rollout() {
  echo "Aborting canary rollout and restoring main as sole active slot."

  ensure_transversal_exists
  ensure_slot_ready "main"

  local listener_arn main_tg
  listener_arn="$(ingress_listener_arn)"
  main_tg="$(slot_target_group_arn "main")"

  set_listener_single_target "$listener_arn" "$main_tg"
  switch_primary_dns_to_ingress_if_configured
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
