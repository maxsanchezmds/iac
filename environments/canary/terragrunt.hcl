include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../infra"
}

dependency "transversal" {
  config_path = "../transversal"

  mock_outputs = {
    vpc_id                = "vpc-00000000000000000"
    private_subnets       = ["subnet-00000000000000001", "subnet-00000000000000002"]
    public_subnets        = ["subnet-00000000000000003", "subnet-00000000000000004"]
    vpc_cidr_block        = "10.0.0.0/16"
    alb_security_group_id = "sg-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  environment                  = "canary"
  shared_vpc_id                = dependency.transversal.outputs.vpc_id
  shared_private_subnets       = dependency.transversal.outputs.private_subnets
  shared_public_subnets        = dependency.transversal.outputs.public_subnets
  shared_vpc_cidr_block        = dependency.transversal.outputs.vpc_cidr_block
  shared_alb_security_group_id = dependency.transversal.outputs.alb_security_group_id
}
