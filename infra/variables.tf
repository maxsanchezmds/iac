variable "environment" {
  description = "Entorno inyectado por Terragrunt: main o pr-<numero>"
  type        = string

  validation {
    condition     = can(regex("^(main|pr-[0-9]+)$", var.environment))
    error_message = "environment debe ser 'main' o 'pr-<numero>' (ej. pr-123)."
  }
}

variable "shared_vpc_id" {
  description = "VPC compartida para slot main (provisionada por transversal)"
  type        = string
  default     = null
}

variable "shared_private_subnets" {
  description = "Subredes privadas compartidas para slot main"
  type        = list(string)
  default     = null
}

variable "shared_public_subnets" {
  description = "Subredes publicas compartidas para slot main"
  type        = list(string)
  default     = null
}

variable "shared_vpc_cidr_block" {
  description = "CIDR de la VPC compartida para slot main"
  type        = string
  default     = null
}

variable "shared_alb_security_group_id" {
  description = "Security Group del ALB de ingress compartido"
  type        = string
  default     = null
}

variable "shared_http_listener_arn" {
  description = "ARN del listener HTTP del ALB de ingress compartido"
  type        = string
  default     = null
}

variable "microservice_data_stores" {
  description = "Capacidades de persistencia por microservicio."
  type = map(object({
    data_stores = set(string)
  }))
  default = {
    inventario = {
      data_stores = ["mongodb"]
    }
    pedidos = {
      data_stores = ["postgres"]
    }
    envios = {
      data_stores = ["postgres"]
    }
    notificaciones = {
      data_stores = ["postgres"]
    }
  }

  validation {
    condition = alltrue([
      for service_name in keys(var.microservice_data_stores) :
      can(regex("^[a-z][a-z0-9-]*$", service_name))
    ])
    error_message = "Los nombres de microservicios deben usar solo minusculas, numeros y guiones, y comenzar con una letra."
  }

  validation {
    condition = alltrue(flatten([
      for _, config in var.microservice_data_stores : [
        for data_store in config.data_stores : contains(["postgres", "mongodb"], data_store)
      ]
    ]))
    error_message = "Cada data_store debe ser uno de: postgres, mongodb."
  }
}

variable "mongodb_connection_strings" {
  description = "MongoDB connection strings por microservicio (ej: inventario)."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = length(setsubtract(
      toset(keys(nonsensitive(var.mongodb_connection_strings))),
      toset([
        for service_name, config in var.microservice_data_stores :
        service_name if contains(config.data_stores, "mongodb")
      ])
    )) == 0
    error_message = "mongodb_connection_strings solo puede incluir microservicios declarados con data_store mongodb."
  }

  validation {
    condition = length(setsubtract(
      toset([
        for service_name, config in var.microservice_data_stores :
        service_name if contains(config.data_stores, "mongodb")
      ]),
      toset(keys(nonsensitive(var.mongodb_connection_strings)))
    )) == 0
    error_message = "Cada microservicio con data_store mongodb debe tener una connection string en mongodb_connection_strings."
  }

  validation {
    condition = alltrue([
      for connection_string in values(nonsensitive(var.mongodb_connection_strings)) :
      can(regex("^mongodb(\\+srv)?://[^\\s:@/]+:[^\\s@/]+@[^\\s/?#]+(/[^\\s?#]*)?(\\?[^\\s#]*)?(#[^\\s]*)?$", connection_string))
    ])
    error_message = "Cada MongoDB connection string debe usar mongodb:// o mongodb+srv:// e incluir credenciales usuario:password@host."
  }
}
