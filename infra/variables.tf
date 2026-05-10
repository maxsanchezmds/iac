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

variable "shared_alb_dns_name" {
  description = "DNS name del ALB de ingress compartido"
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
      data_stores = ["mongodb", "postgres"]
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

variable "sns_event_subscriptions" {
  description = "Eventos SNS que debe recibir cada cola SQS por microservicio."
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue(flatten([
      for service_name, events in var.sns_event_subscriptions : [
        can(regex("^[a-z][a-z0-9-]*$", service_name)),
        length(events) > 0,
        alltrue([
          for event_name in events : can(regex("^[a-z][a-z0-9_]*$", event_name))
        ])
      ]
    ]))
    error_message = "sns_event_subscriptions debe usar microservicios en formato slug y eventos no vacios en snake_case."
  }
}

variable "mongodb_connection_strings" {
  description = "MongoDB connection strings por microservicio (ej: inventario)."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for connection_string in values(nonsensitive(var.mongodb_connection_strings)) :
      can(regex("^mongodb(\\+srv)?://[^\\s:@/]+:[^\\s@/]+@[^\\s/?#]+(/[^\\s?#]*)?(\\?[^\\s#]*)?(#[^\\s]*)?$", connection_string))
    ])
    error_message = "Cada MongoDB connection string debe usar mongodb:// o mongodb+srv:// e incluir credenciales usuario:password@host."
  }
}

variable "client_vpn_enabled" {
  description = "Habilita AWS Client VPN para acceso privado de desarrolladores a recursos de la VPC."
  type        = bool
  default     = false
}

variable "client_vpn_client_cidr_block" {
  description = "CIDR asignado a clientes VPN. No debe solaparse con la VPC ni con redes locales de los devs."
  type        = string
  default     = "172.16.0.0/22"

  validation {
    condition     = can(cidrhost(trimspace(var.client_vpn_client_cidr_block), 0))
    error_message = "client_vpn_client_cidr_block debe ser un CIDR valido."
  }
}

variable "client_vpn_server_certificate_arn" {
  description = "ARN ACM del certificado de servidor para AWS Client VPN. Requerido si client_vpn_enabled=true."
  type        = string
  default     = null
}

variable "client_vpn_root_certificate_arn" {
  description = "ARN ACM de la CA raiz que firma certificados de cliente. Requerido si client_vpn_enabled=true."
  type        = string
  default     = null
}

variable "client_vpn_cloudwatch_log_retention_days" {
  description = "Dias de retencion para logs de conexion de AWS Client VPN."
  type        = number
  default     = 30
}
