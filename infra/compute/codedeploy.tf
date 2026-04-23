resource "aws_codedeploy_app" "kong" {
  count            = var.enable_kong_codedeploy ? 1 : 0
  name             = "codedeploy-kong-${var.environment}"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "kong" {
  count                  = var.enable_kong_codedeploy ? 1 : 0
  app_name               = aws_codedeploy_app.kong[0].name
  deployment_group_name  = "dg-kong-${var.environment}"
  service_role_arn       = var.codedeploy_service_role_arn
  deployment_config_name = var.codedeploy_deployment_config_name

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
      "DEPLOYMENT_STOP_ON_ALARM",
      "DEPLOYMENT_STOP_ON_REQUEST"
    ]
  }

  dynamic "alarm_configuration" {
    for_each = length(var.codedeploy_alarm_names) > 0 ? [1] : []
    content {
      enabled                   = true
      ignore_poll_alarm_failure = false
      alarms                    = var.codedeploy_alarm_names
    }
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.kong.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.kong_blue.name
      }

      target_group {
        name = aws_lb_target_group.kong_green.name
      }

      prod_traffic_route {
        listener_arns = [local.kong_listener_arn]
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.codedeploy_service_role_arn != null
      error_message = "codedeploy_service_role_arn es requerido cuando enable_kong_codedeploy = true."
    }
    precondition {
      condition     = local.kong_listener_arn != null
      error_message = "No se pudo resolver listener ARN para CodeDeploy."
    }
  }
}
