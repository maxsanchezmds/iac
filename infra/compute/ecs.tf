resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster-smartlogix-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    weight            = 1
    capacity_provider = "FARGATE"
  }
}

resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = local.service_discovery_namespace_name
  description = "Service discovery DNS para ruteo de Kong a NestJS"
  vpc         = var.vpc_id
}

locals {
  alb_security_group_id = var.ingress_mode == "dedicated" ? aws_security_group.alb[0].id : var.shared_alb_security_group_id
  # Shared ingress slots run in the same VPC, so each slot needs a distinct namespace domain.
  service_discovery_namespace_name = var.ingress_mode == "shared" ? "smartlogix-${var.environment}.local" : "smartlogix.local"
}

resource "aws_security_group" "ecs_tasks" {
  name   = "ecs-tasks-sg-smartlogix-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [local.alb_security_group_id]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    precondition {
      condition     = var.ingress_mode != "shared" || var.shared_alb_security_group_id != null
      error_message = "shared_alb_security_group_id es requerido cuando ingress_mode = shared."
    }
  }
}
