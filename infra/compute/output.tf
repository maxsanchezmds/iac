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

output "cloudmap_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.internal.id
}

output "target_group_kong_arn" {
  value = aws_lb_target_group.kong.arn
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}
