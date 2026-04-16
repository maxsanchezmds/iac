locals {
  microservicios = [
    "inventario",
    "pedidos",
    "envios",
    "notificaciones"
  ]

  use_shared_ingress = contains(["main", "canary"], var.environment)

  vpc_id = local.use_shared_ingress ? var.shared_vpc_id : module.networking[0].vpc_id

  private_subnets = local.use_shared_ingress ? var.shared_private_subnets : module.networking[0].private_subnets

  public_subnets = local.use_shared_ingress ? var.shared_public_subnets : module.networking[0].public_subnets

  vpc_cidr_block = local.use_shared_ingress ? var.shared_vpc_cidr_block : module.networking[0].vpc_cidr_block
}

module "security" {
  source         = "./security"
  environment    = var.environment
  microservicios = local.microservicios
}

module "networking" {
  count       = local.use_shared_ingress ? 0 : 1
  source      = "./networking"
  environment = var.environment
}

module "database" {
  source          = "./database"
  environment     = var.environment
  vpc_id          = local.vpc_id
  private_subnets = local.private_subnets
  vpc_cidr_block  = local.vpc_cidr_block
  microservicios  = local.microservicios
  db_passwords    = module.security.db_passwords
}

module "compute" {
  source                       = "./compute"
  environment                  = var.environment
  ingress_mode                 = local.use_shared_ingress ? "shared" : "dedicated"
  shared_alb_security_group_id = local.use_shared_ingress ? var.shared_alb_security_group_id : null
  vpc_id                       = local.vpc_id
  public_subnets               = local.public_subnets
  private_subnets              = local.private_subnets
  microservicios               = local.microservicios
  ecs_execution_role_arn       = module.security.ecs_execution_role_arn
  ecs_task_role_arn            = module.security.ecs_task_role_arn
  db_parameter_arns            = module.security.ssm_parameter_arns
}

module "storage" {
  source         = "./storage"
  environment    = var.environment
  microservicios = local.microservicios
}
