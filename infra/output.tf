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
