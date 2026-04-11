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
  name        = "smartlogix.local"
  description = "Service discovery DNS para ruteo de Kong a NestJS"
  vpc         = var.vpc_id
}

resource "aws_security_group" "ecs_tasks" {
  name   = "sg-ecs-tasks-smartlogix-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
}