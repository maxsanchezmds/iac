variable "environment" {
  type = string
}

variable "ingress_mode" {
  description = "Modo de ingress: dedicated crea ALB+listener local; shared usa ALB transversal."
  type        = string
  default     = "dedicated"

  validation {
    condition     = contains(["dedicated", "shared"], var.ingress_mode)
    error_message = "ingress_mode debe ser 'dedicated' o 'shared'."
  }
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "microservicios" {
  type = list(string)
}

variable "ecs_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "db_parameter_arns" {
  type = map(string)
}

variable "shared_alb_security_group_id" {
  description = "Security Group del ALB compartido (requerido cuando ingress_mode=shared)."
  type        = string
  default     = null
}

variable "shared_http_listener_arn" {
  description = "ARN del listener HTTP del ALB compartido (requerido cuando ingress_mode=shared)."
  type        = string
  default     = null
}

