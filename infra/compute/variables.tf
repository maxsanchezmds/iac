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