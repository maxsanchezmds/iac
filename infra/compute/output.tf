output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
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
