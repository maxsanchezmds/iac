variable "environment" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "private_subnets" {
  type        = list(string)
}

variable "vpc_cidr_block" {
  type        = string
}

variable "microservicios" {
  type        = list(string)
}

variable "db_passwords" {
  type        = map(string)
  sensitive   = true
}