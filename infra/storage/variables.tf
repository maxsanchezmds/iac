variable "environment" {
  description = "Entorno de despliegue (main, canary o pr-<numero>)"
  type        = string
}

variable "microservicios" {
  type = list(string)
}
