variable "environment" {
  description = "Define el tipo de entorno (Desarrollo o produccion ('dev' o 'prod'))"
  type        = string
}

variable "microservicios" {
  type = list(string)
}