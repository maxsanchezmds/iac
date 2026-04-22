resource "aws_ecr_repository" "microservicios" {
  for_each             = toset(var.microservicios)
  name                 = "smartlogix-${each.key}-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "kong" {
  name                 = "smartlogix-kong-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
