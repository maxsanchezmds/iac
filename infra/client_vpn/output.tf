output "endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.main.id
}

output "security_group_id" {
  value = aws_security_group.client_vpn.id
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.client_vpn.name
}
