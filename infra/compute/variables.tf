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

variable "codedeploy_service_role_arn" {
  description = "IAM role ARN used by CodeDeploy ECS blue/green deployments."
  type        = string
  default     = null
}

variable "service_secret_arns" {
  description = "ARNs de secretos SSM por microservicio y nombre de variable de entorno."
  type        = map(map(string))
  default     = {}
}

variable "service_environment" {
  description = "Variables de entorno no sensibles por microservicio."
  type        = map(map(string))
  default     = {}
}

variable "kong_image" {
  description = "Container image for Kong."
  type        = string
  default     = "kong:3.7"
}

variable "enable_kong_codedeploy" {
  description = "Enable CodeDeploy blue/green for the Kong ECS service."
  type        = bool
  default     = false
}

variable "codedeploy_deployment_config_name" {
  description = "Custom CodeDeploy ECS deployment config name (50% canary for 5 minutes)."
  type        = string
  default     = "codedeploy-kong-canary50-5m"
}

variable "codedeploy_alarm_names" {
  description = "CloudWatch alarm names that trigger automatic rollback."
  type        = list(string)
  default     = []
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

