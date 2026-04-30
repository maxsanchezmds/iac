output "kong_repository_url" {
  value = aws_ecr_repository.kong.repository_url
}

output "microservice_repository_urls" {
  value = { for service, repository in aws_ecr_repository.microservicios : service => repository.repository_url }
}

output "events_topic_arn" {
  value = aws_sns_topic.eventos.arn
}

output "queue_arns" {
  value = { for service, queue in aws_sqs_queue.colas : service => queue.arn }
}

output "queue_urls" {
  value = { for service, queue in aws_sqs_queue.colas : service => queue.url }
}
