variable "environment" {
  type = string
}

variable "postgres_services" {
  type = list(string)
}

variable "mongodb_services" {
  type    = list(string)
  default = []
}

variable "mongodb_connection_strings" {
  type      = map(string)
  default   = {}
  sensitive = true
}
