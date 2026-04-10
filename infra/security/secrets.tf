resource "random_password" "db_password" {
  for_each         = toset(var.microservicios)
  length           = 16
  special          = true
  override_special = "_-^!" 
}

resource "aws_ssm_parameter" "db_password" {
  for_each    = toset(var.microservicios)
  name        = "/smartlogix/${var.environment}/${each.key}/db_password"
  description = "Contraseña de base de datos para el microservicio ${each.key}"
  type        = "SecureString"
  value       = random_password.db_password[each.key].result
}