output "db_passwords" {
  value     = { for ms in var.microservicios : ms => random_password.db_password[ms].result }
  sensitive = true
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "ssm_parameter_arns" {
  value = { for ms in var.microservicios : ms => aws_ssm_parameter.db_password[ms].arn }
}