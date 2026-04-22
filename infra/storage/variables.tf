variable "environment" {
  description = "Entorno de despliegue (main o pr-<numero>)"
  type        = string
}

variable "microservicios" {
  type = list(string)
}
