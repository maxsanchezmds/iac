output "environment" {
  value = var.environment
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "alb_zone_id" {
  value = module.compute.alb_zone_id
}

output "alb_arn" {
  value = module.compute.alb_arn
}

output "http_listener_arn" {
  value = module.compute.http_listener_arn
}

output "target_group_kong_arn" {
  value = module.compute.target_group_kong_arn
}

output "ecs_cluster_id" {
  value = module.compute.ecs_cluster_id
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}

output "kong_service_name" {
  value = module.compute.kong_service_name
}

output "kong_codedeploy_app_name" {
  value = module.compute.kong_codedeploy_app_name
}

output "kong_codedeploy_deployment_group_name" {
  value = module.compute.kong_codedeploy_deployment_group_name
}

output "kong_ecr_repository_url" {
  value = module.storage.kong_repository_url
}

output "pedidos_ecr_repository_url" {
  value = try(module.storage.microservice_repository_urls["pedidos"], null)
}

output "microservice_ecr_repository_urls" {
  value = module.storage.microservice_repository_urls
}

output "pedidos_service_name" {
  value = try(module.compute.microservice_service_names["pedidos"], null)
}

output "microservice_service_names" {
  value = module.compute.microservice_service_names
}

output "events_topic_arn" {
  value = module.storage.events_topic_arn
}

output "inventario_queue_url" {
  value = try(module.storage.queue_urls["inventario"], null)
}

output "microservice_queue_urls" {
  value = module.storage.queue_urls
}

output "client_vpn_endpoint_id" {
  value = try(module.client_vpn[0].endpoint_id, null)
}

output "client_vpn_security_group_id" {
  value = try(module.client_vpn[0].security_group_id, null)
}

output "client_vpn_log_group_name" {
  value = try(module.client_vpn[0].cloudwatch_log_group_name, null)
}

output "frontend_bucket_name" {
  value = try(module.frontend[0].bucket_name, null)
}

output "frontend_cloudfront_distribution_id" {
  value = try(module.frontend[0].cloudfront_distribution_id, null)
}

output "frontend_app_url" {
  value = try(module.frontend[0].app_url, null)
}
