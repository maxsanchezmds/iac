variable "environment" {
  description = "Entorno de despliegue (main o pr-<numero>)"
  type        = string
}

variable "microservicios" {
  type = list(string)
}

variable "sns_event_subscriptions" {
  description = "Eventos SNS que debe recibir cada cola SQS por microservicio."
  type        = map(list(string))
  default     = {}
}
