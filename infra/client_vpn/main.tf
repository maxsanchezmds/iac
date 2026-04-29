resource "aws_cloudwatch_log_group" "client_vpn" {
  name              = "/aws/client-vpn/smartlogix-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_stream" "client_vpn" {
  name           = "connections"
  log_group_name = aws_cloudwatch_log_group.client_vpn.name
}

resource "aws_security_group" "client_vpn" {
  name        = "client-vpn-sg-smartlogix-${var.environment}"
  description = "Permite trafico desde clientes AWS Client VPN hacia recursos privados"
  vpc_id      = var.vpc_id

  egress {
    description = "Trafico privado dentro de la VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }
}

resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "client-vpn-smartlogix-${var.environment}"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = true
  transport_protocol     = "udp"
  vpn_port               = 443
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.client_vpn.id]
  dns_servers            = [cidrhost(var.vpc_cidr_block, 2)]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_root_certificate_chain_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn.name
  }
}

resource "aws_ec2_client_vpn_network_association" "private" {
  for_each = toset(var.private_subnets)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = each.value
}

resource "aws_ec2_client_vpn_authorization_rule" "private" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr    = var.authorization_target_cidr
  authorize_all_groups   = true

  depends_on = [aws_ec2_client_vpn_network_association.private]
}
