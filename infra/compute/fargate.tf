resource "aws_service_discovery_service" "kong" {
  name = "kong"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_service_discovery_service" "microservicios" {
  for_each = toset(var.microservicios)
  name     = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "kong" {
  family                   = "kong-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "kong"
    image     = var.kong_image
    essential = true
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
    }]
    environment = [
      { name = "KONG_DATABASE", value = "off" }, # Kong en modo DB-less
      { name = "KONG_PROXY_ACCESS_LOG", value = "/dev/stdout" },
      { name = "KONG_ADMIN_ACCESS_LOG", value = "/dev/stdout" },
      { name = "KONG_PROXY_ERROR_LOG", value = "/dev/stderr" },
      { name = "KONG_ADMIN_ERROR_LOG", value = "/dev/stderr" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.kong.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "kong"
      }
    }
  }])
}

resource "aws_ecs_service" "kong" {
  name                              = "srv-kong-${var.environment}"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.kong.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kong_blue.arn
    container_name   = "kong"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.kong.arn
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.shared_kong_bootstrap
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  deployment_controller {
    type = var.enable_kong_codedeploy ? "CODE_DEPLOY" : "ECS"
  }
}

resource "aws_ecs_task_definition" "microservicios" {
  for_each                 = toset(var.microservicios)
  family                   = "${each.key}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = each.key
    image     = "alpine:latest" # IMAGEN IRRELEVANTE: GitHub la reemplazará en el primer push a main
    essential = true
    command   = ["tail", "-f", "/dev/null"]
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
    secrets = [
      {
        name      = "DATABASE_PASSWORD"
        valueFrom = var.db_parameter_arns[each.key]
      }
    ]
    environment = [
      { name = "PORT", value = "3000" },
      { name = "NODE_ENV", value = var.environment }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.microservicios[each.key].name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "app"
      }
    }
  }])
}

resource "aws_ecs_service" "microservicios" {
  for_each        = toset(var.microservicios)
  name            = "srv-${each.key}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservicios[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.microservicios[each.key].arn
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
