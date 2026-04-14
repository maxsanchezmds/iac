output "alb_dns_name" {
  value = aws_lb.ingress.dns_name
}

output "alb_zone_id" {
  value = aws_lb.ingress.zone_id
}

output "alb_arn" {
  value = aws_lb.ingress.arn
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "alb_security_group_id" {
  value = aws_security_group.ingress_alb.id
}
