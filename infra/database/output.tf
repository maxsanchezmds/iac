output "postgres_connection_environment" {
  description = "Variables de entorno no sensibles necesarias para conectar cada microservicio a su RDS PostgreSQL."
  value = {
    for service, db in aws_db_instance.databases : service => {
      DATABASE_HOST = db.address
      DATABASE_PORT = tostring(db.port)
      DATABASE_NAME = local.postgres_database_names[service]
      DATABASE_USER = local.postgres_usernames[service]
    }
  }
}

output "postgres_connection_url_ssm_parameter_arns" {
  description = "ARNs de los parametros SSM SecureString con DATABASE_URL PostgreSQL por microservicio."
  value       = { for service, parameter in aws_ssm_parameter.postgres_connection_url : service => parameter.arn }
}
