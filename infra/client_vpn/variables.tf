variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnets" {
  type = list(string)

  validation {
    condition     = length(var.private_subnets) > 0
    error_message = "private_subnets debe contener al menos una subnet privada para asociar el Client VPN."
  }
}

variable "client_cidr_block" {
  description = "CIDR asignado a clientes VPN. No debe solaparse con la VPC ni con redes locales de los devs."
  type        = string
  default     = "172.16.0.0/22"
}

variable "server_certificate_arn" {
  description = "ARN ACM del certificado de servidor para AWS Client VPN."
  type        = string
}

variable "client_root_certificate_chain_arn" {
  description = "ARN ACM de la CA raiz que firma certificados de cliente."
  type        = string
}

variable "authorization_target_cidr" {
  description = "CIDR privado autorizado para clientes VPN."
  type        = string
}

variable "cloudwatch_log_retention_days" {
  description = "Retencion de logs de conexion del Client VPN."
  type        = number
  default     = 30
}
