output "alb_dns_name" {
  value = local.use_dedicated_ingress ? aws_lb.main[0].dns_name : null
}

output "alb_zone_id" {
  value = local.use_dedicated_ingress ? aws_lb.main[0].zone_id : null
}

output "alb_arn" {
  value = local.use_dedicated_ingress ? aws_lb.main[0].arn : null
}

output "http_listener_arn" {
  value = local.use_dedicated_ingress ? aws_lb_listener.http[0].arn : null
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "kong_service_name" {
  value = aws_ecs_service.kong.name
}

output "kong_task_definition_family" {
  value = aws_ecs_task_definition.kong.family
}

output "kong_container_name" {
  value = "kong"
}

output "kong_container_port" {
  value = 8000
}

output "kong_listener_arn" {
  value = local.kong_listener_arn
}

output "cloudmap_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.internal.id
}

output "cloudmap_namespace_name" {
  value = local.service_discovery_namespace_name
}

output "target_group_kong_arn" {
  value = aws_lb_target_group.kong_blue.arn
}

output "target_group_kong_blue_arn" {
  value = aws_lb_target_group.kong_blue.arn
}

output "target_group_kong_green_arn" {
  value = aws_lb_target_group.kong_green.arn
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "kong_codedeploy_app_name" {
  value = var.enable_kong_codedeploy ? aws_codedeploy_app.kong[0].name : null
}

output "kong_codedeploy_deployment_group_name" {
  value = var.enable_kong_codedeploy ? aws_codedeploy_deployment_group.kong[0].deployment_group_name : null
}

output "microservice_service_names" {
  value = { for service, ecs_service in aws_ecs_service.microservicios : service => ecs_service.name }
}

output "microservice_task_definition_families" {
  value = { for service, task_definition in aws_ecs_task_definition.microservicios : service => task_definition.family }
}

output "microservice_container_names" {
  value = { for service in var.microservicios : service => service }
}

output "microservice_container_ports" {
  value = { for service in var.microservicios : service => 3000 }
}

output "microservice_discovery_service_arns" {
  value = { for service, discovery_service in aws_service_discovery_service.microservicios : service => discovery_service.arn }
}

output "microservice_canary_discovery_service_arns" {
  value = { for service, discovery_service in aws_service_discovery_service.microservicios_canary : service => discovery_service.arn }
}
