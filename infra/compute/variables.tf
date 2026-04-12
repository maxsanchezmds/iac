variable "environment" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "public_subnets" {
  type        = list(string)
}

variable "private_subnets" {
  type        = list(string)
}

variable "microservicios" {
  type        = list(string)
}

variable "ecs_execution_role_arn" {
  type        = string
}

variable "ecs_task_role_arn" {
  type        = string
}

variable "db_parameter_arns" {
  type        = map(string)
}