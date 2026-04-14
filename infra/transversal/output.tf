output "vpc_id" {
  value = module.networking.vpc_id
}

output "private_subnets" {
  value = module.networking.private_subnets
}

output "public_subnets" {
  value = module.networking.public_subnets
}

output "vpc_cidr_block" {
  value = module.networking.vpc_cidr_block
}

output "alb_dns_name" {
  value = module.ingress.alb_dns_name
}

output "alb_zone_id" {
  value = module.ingress.alb_zone_id
}

output "alb_arn" {
  value = module.ingress.alb_arn
}

output "http_listener_arn" {
  value = module.ingress.http_listener_arn
}

output "alb_security_group_id" {
  value = module.ingress.alb_security_group_id
}
