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
