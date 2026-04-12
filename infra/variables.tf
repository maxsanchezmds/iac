variable "environment" {
  description = "Entorno inyectado por Terragrunt: main, canary o pr-<numero>"
  type        = string

  validation {
    condition     = can(regex("^(main|canary|pr-[0-9]+)$", var.environment))
    error_message = "environment debe ser 'main', 'canary' o 'pr-<numero>' (ej. pr-123)."
  }
}
