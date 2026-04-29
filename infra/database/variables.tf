variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_cidr_block" {
  type = string
}

variable "postgres_services" {
  type = list(string)
}

variable "postgres_passwords" {
  type      = map(string)
  sensitive = true
}

variable "postgres_allowed_security_group_ids" {
  description = "Security Groups adicionales autorizados a conectarse a PostgreSQL por 5432."
  type        = list(string)
  default     = []
}
