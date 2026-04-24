output "postgres_db_passwords" {
  value     = { for ms in var.postgres_services : ms => random_password.db_password[ms].result }
  sensitive = true
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "postgres_db_password_ssm_parameter_arns" {
  value = { for ms in var.postgres_services : ms => aws_ssm_parameter.db_password[ms].arn }
}

output "mongodb_connection_string_ssm_parameter_arns" {
  value = { for ms in local.mongodb_connection_string_services : ms => aws_ssm_parameter.mongodb_connection_string[ms].arn }
}

output "codedeploy_service_role_arn" {
  value = aws_iam_role.codedeploy_role.arn
}
