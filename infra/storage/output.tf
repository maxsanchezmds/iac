output "kong_repository_url" {
  value = aws_ecr_repository.kong.repository_url
}

output "microservice_repository_urls" {
  value = { for service, repository in aws_ecr_repository.microservicios : service => repository.repository_url }
}
