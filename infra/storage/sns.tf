resource "aws_sns_topic" "eventos" {
  name = "eventos-smartlogix-${var.environment}"
}