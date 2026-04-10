include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../infra/compute"
}

dependency "network_base" {
  config_path = "../transversal"
}

inputs = {
  environment     = "prod"
  vpc_id          = dependency.network_base.outputs.vpc_id
  private_subnets = dependency.network_base.outputs.private_subnets
}