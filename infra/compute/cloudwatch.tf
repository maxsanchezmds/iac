resource "aws_cloudwatch_log_group" "kong" {
  name              = "/ecs/smartlogix-kong-${var.environment}"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "microservicios" {
  for_each          = toset(var.microservicios)
  name              = "/ecs/smartlogix-${each.key}-${var.environment}"
  retention_in_days = 3
}