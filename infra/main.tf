module "networking" {
  source      = "./networking"
  environment = var.environment
}

module "database" {
  source      = "./database"
  environment = var.environment
  vpc_id      = module.networking.vpc_id
}

module "compute" {
  source      = "./compute"
  environment = var.environment
  vpc_id      = module.networking.vpc_id
}