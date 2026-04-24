locals {
  mongodb_connection_string_services = toset(var.mongodb_services)
}

resource "random_password" "db_password" {
  for_each         = toset(var.postgres_services)
  length           = 16
  special          = true
  override_special = "_-^!"
}

resource "aws_ssm_parameter" "db_password" {
  for_each    = toset(var.postgres_services)
  name        = "/smartlogix/${var.environment}/${each.key}/db_password"
  description = "Contraseña de base de datos para el microservicio ${each.key}"
  type        = "SecureString"
  value       = random_password.db_password[each.key].result
}

resource "aws_ssm_parameter" "mongodb_connection_string" {
  for_each    = local.mongodb_connection_string_services
  name        = "/smartlogix/${var.environment}/${each.value}/mongodb_uri"
  description = "MongoDB URI para el microservicio ${each.value}"
  type        = "SecureString"
  value       = var.mongodb_connection_strings[each.value]
}
