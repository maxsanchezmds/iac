variable "environment" {
  description = "Entorno de despliegue."
  type        = string
}

variable "api_origin_domain_name" {
  description = "DNS name del ALB que atiende las rutas API por medio de Kong."
  type        = string
}
