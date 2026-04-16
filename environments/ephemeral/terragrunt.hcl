include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../infra"
}

locals {
  aws_region   = "us-east-1"
  pr_number    = trimspace(get_env("PR_NUMBER", ""))
  environment  = "pr-${local.pr_number}"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "s3-tf-state-smartlogix-2026"
    key            = "environments/ephemeral/${local.environment}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "dynamo-tfstate-smartlogix-2026"
  }
}

inputs = {
  environment = local.environment
}
