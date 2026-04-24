locals {
  microservice_catalog = var.microservice_data_stores
  microservicios       = sort(keys(local.microservice_catalog))
  postgres_microservicios = [
    for ms in local.microservicios : ms if contains(local.microservice_catalog[ms].data_stores, "postgres")
  ]
  mongodb_microservicios = [
    for ms in local.microservicios : ms if contains(local.microservice_catalog[ms].data_stores, "mongodb")
  ]
  service_secret_arns = {
    for ms in local.microservicios : ms => merge(
      contains(keys(module.security.postgres_db_password_ssm_parameter_arns), ms) ? {
        DATABASE_PASSWORD = module.security.postgres_db_password_ssm_parameter_arns[ms]
      } : {},
      contains(keys(module.database.postgres_connection_url_ssm_parameter_arns), ms) ? {
        DATABASE_URL = module.database.postgres_connection_url_ssm_parameter_arns[ms]
      } : {},
      contains(keys(module.security.mongodb_connection_string_ssm_parameter_arns), ms) ? {
        MONGODB_URI = module.security.mongodb_connection_string_ssm_parameter_arns[ms]
      } : {}
    )
  }
  service_environment = {
    for ms in local.microservicios : ms => merge(
      contains(keys(module.database.postgres_connection_environment), ms) ? module.database.postgres_connection_environment[ms] : {}
    )
  }

  use_shared_ingress = var.environment == "main"

  vpc_id = local.use_shared_ingress ? var.shared_vpc_id : module.networking[0].vpc_id

  private_subnets = local.use_shared_ingress ? var.shared_private_subnets : module.networking[0].private_subnets

  public_subnets = local.use_shared_ingress ? var.shared_public_subnets : module.networking[0].public_subnets

  vpc_cidr_block = local.use_shared_ingress ? var.shared_vpc_cidr_block : module.networking[0].vpc_cidr_block
}

module "security" {
  source                     = "./security"
  environment                = var.environment
  postgres_services          = local.postgres_microservicios
  mongodb_services           = local.mongodb_microservicios
  mongodb_connection_strings = var.mongodb_connection_strings
}

module "networking" {
  count       = local.use_shared_ingress ? 0 : 1
  source      = "./networking"
  environment = var.environment
}

module "database" {
  source             = "./database"
  environment        = var.environment
  vpc_id             = local.vpc_id
  private_subnets    = local.private_subnets
  vpc_cidr_block     = local.vpc_cidr_block
  postgres_services  = local.postgres_microservicios
  postgres_passwords = module.security.postgres_db_passwords
}

module "compute" {
  source                       = "./compute"
  environment                  = var.environment
  ingress_mode                 = local.use_shared_ingress ? "shared" : "dedicated"
  shared_alb_security_group_id = local.use_shared_ingress ? var.shared_alb_security_group_id : null
  shared_http_listener_arn     = local.use_shared_ingress ? var.shared_http_listener_arn : null
  vpc_id                       = local.vpc_id
  public_subnets               = local.public_subnets
  private_subnets              = local.private_subnets
  microservicios               = local.microservicios
  ecs_execution_role_arn       = module.security.ecs_execution_role_arn
  ecs_task_role_arn            = module.security.ecs_task_role_arn
  codedeploy_service_role_arn  = module.security.codedeploy_service_role_arn
  enable_kong_codedeploy       = var.environment == "main"
  service_secret_arns          = local.service_secret_arns
  service_environment          = local.service_environment
}

module "storage" {
  source         = "./storage"
  environment    = var.environment
  microservicios = local.microservicios
}
