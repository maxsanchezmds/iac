locals {
  publish_kong_deploy_contract          = var.environment == "main"
  publish_microservice_deploy_contracts = var.environment == "main"
  kong_deploy_contract_parameters = local.publish_kong_deploy_contract ? {
    "/smartlogix/kong/deploy/cluster_name"                     = module.compute.ecs_cluster_name
    "/smartlogix/kong/deploy/service_name"                     = module.compute.kong_service_name
    "/smartlogix/kong/deploy/listener_arn"                     = module.compute.kong_listener_arn
    "/smartlogix/kong/deploy/private_subnet_ids_csv"           = join(",", local.private_subnets)
    "/smartlogix/kong/deploy/security_group_id"                = module.compute.ecs_tasks_sg_id
    "/smartlogix/kong/deploy/vpc_id"                           = local.vpc_id
    "/smartlogix/kong/deploy/container_name"                   = module.compute.kong_container_name
    "/smartlogix/kong/deploy/container_port"                   = tostring(module.compute.kong_container_port)
    "/smartlogix/kong/deploy/task_definition_family"           = module.compute.kong_task_definition_family
    "/smartlogix/kong/deploy/cloudmap_namespace_name"          = module.compute.cloudmap_namespace_name
    "/smartlogix/kong/deploy/codedeploy_app_name"              = module.compute.kong_codedeploy_app_name
    "/smartlogix/kong/deploy/codedeploy_deployment_group_name" = module.compute.kong_codedeploy_deployment_group_name
    "/smartlogix/kong/deploy/ecr_repository_url"               = module.storage.kong_repository_url
  } : {}
  microservice_deploy_contract_parameters = local.publish_microservice_deploy_contracts ? merge([
    for service in local.microservicios : {
      "/smartlogix/${service}/deploy/cluster_name"                 = module.compute.ecs_cluster_name
      "/smartlogix/${service}/deploy/service_name"                 = module.compute.microservice_service_names[service]
      "/smartlogix/${service}/deploy/canary_service_name"          = "srv-${service}-canary-main"
      "/smartlogix/${service}/deploy/container_name"               = module.compute.microservice_container_names[service]
      "/smartlogix/${service}/deploy/container_port"               = tostring(module.compute.microservice_container_ports[service])
      "/smartlogix/${service}/deploy/task_definition_family"       = module.compute.microservice_task_definition_families[service]
      "/smartlogix/${service}/deploy/ecr_repository_url"           = module.storage.microservice_repository_urls[service]
      "/smartlogix/${service}/deploy/canary_discovery_service_arn" = module.compute.microservice_canary_discovery_service_arns[service]
      "/smartlogix/${service}/deploy/events_topic_arn"             = module.storage.events_topic_arn
      "/smartlogix/${service}/deploy/queue_url"                    = module.storage.queue_urls[service]
      "/smartlogix/${service}/deploy/queue_arn"                    = module.storage.queue_arns[service]
    }
  ]...) : {}
}

resource "aws_ssm_parameter" "kong_deploy_contract" {
  for_each  = local.kong_deploy_contract_parameters
  name      = each.key
  type      = "String"
  overwrite = true
  value     = each.value
}

resource "aws_ssm_parameter" "microservice_deploy_contract" {
  for_each  = local.microservice_deploy_contract_parameters
  name      = each.key
  type      = "String"
  overwrite = true
  value     = each.value
}
