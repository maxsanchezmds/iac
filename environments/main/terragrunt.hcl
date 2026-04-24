include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infra"
}

locals {
  use_mock_dependency = lower(get_env("TG_USE_MOCK_DEPENDENCY", "false")) == "true"
  transversal_mock_outputs = {
    vpc_id                = "vpc-00000000000000000"
    private_subnets       = ["subnet-00000000000000001", "subnet-00000000000000002"]
    public_subnets        = ["subnet-00000000000000003", "subnet-00000000000000004"]
    vpc_cidr_block        = "10.0.0.0/16"
    alb_security_group_id = "sg-00000000000000000"
    http_listener_arn     = "arn:aws:elasticloadbalancing:us-east-1:000000000000:listener/app/alb-smartlogix-transversal/0000000000000000/0000000000000000"
  }
}

dependency "transversal" {
  config_path  = "../transversal"
  skip_outputs = local.use_mock_dependency

  mock_outputs                            = local.transversal_mock_outputs
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "output"]
}

inputs = {
  environment                  = "main"
  shared_vpc_id                = local.use_mock_dependency ? local.transversal_mock_outputs.vpc_id : dependency.transversal.outputs.vpc_id
  shared_private_subnets       = local.use_mock_dependency ? local.transversal_mock_outputs.private_subnets : dependency.transversal.outputs.private_subnets
  shared_public_subnets        = local.use_mock_dependency ? local.transversal_mock_outputs.public_subnets : dependency.transversal.outputs.public_subnets
  shared_vpc_cidr_block        = local.use_mock_dependency ? local.transversal_mock_outputs.vpc_cidr_block : dependency.transversal.outputs.vpc_cidr_block
  shared_alb_security_group_id = local.use_mock_dependency ? local.transversal_mock_outputs.alb_security_group_id : dependency.transversal.outputs.alb_security_group_id
  shared_http_listener_arn     = local.use_mock_dependency ? local.transversal_mock_outputs.http_listener_arn : dependency.transversal.outputs.http_listener_arn
}
