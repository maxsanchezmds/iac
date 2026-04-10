locals {
  microservicios = [
    "inventario",
    "pedidos",
    "envios",
    "notificaciones"
  ]
}

module "security" {
  source         = "./security"
  environment    = var.environment
  microservicios = local.microservicios
}

module "networking" {
  source      = "./networking"
  environment = var.environment
}

module "database" {
  source          = "./database"
  environment     = var.environment
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnets
  vpc_cidr_block  = module.networking.vpc_cidr_block
  microservicios  = local.microservicios
  db_passwords    = module.security.db_passwords
}

module "compute" {
  source      = "./compute"
  environment = var.environment
  vpc_id      = module.networking.vpc_id
}

module "storage" {
  source         = "./storage"
  environment    = var.environment
  microservicios = local.microservicios
}