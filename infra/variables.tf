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
