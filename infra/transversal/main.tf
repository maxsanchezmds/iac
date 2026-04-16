module "networking" {
  source      = "../networking"
  environment = var.environment
}

module "ingress" {
  source         = "../ingress"
  environment    = var.environment
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnets
}
