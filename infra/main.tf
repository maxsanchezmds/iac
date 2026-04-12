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
  source                 = "./compute"
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  public_subnets         = module.networking.public_subnets
  private_subnets        = module.networking.private_subnets
  microservicios         = local.microservicios
  ecs_execution_role_arn = module.security.ecs_execution_role_arn
  ecs_task_role_arn      = module.security.ecs_task_role_arn
  db_parameter_arns      = module.security.ssm_parameter_arns
}

module "storage" {
  source         = "./storage"
  environment    = var.environment
  microservicios = local.microservicios
}