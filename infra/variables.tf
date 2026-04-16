variable "environment" {
  description = "Entorno inyectado por Terragrunt: main, canary o pr-<numero>"
  type        = string

  validation {
    condition     = can(regex("^(main|canary|pr-[0-9]+)$", var.environment))
    error_message = "environment debe ser 'main', 'canary' o 'pr-<numero>' (ej. pr-123)."
  }
}

variable "shared_vpc_id" {
  description = "VPC compartida para slots main/canary (provisionada por transversal)"
  type        = string
  default     = null
}

variable "shared_private_subnets" {
  description = "Subredes privadas compartidas para slots main/canary"
  type        = list(string)
  default     = null
}

variable "shared_public_subnets" {
  description = "Subredes publicas compartidas para slots main/canary"
  type        = list(string)
  default     = null
}

variable "shared_vpc_cidr_block" {
  description = "CIDR de la VPC compartida para slots main/canary"
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
