resource "aws_ecr_repository" "microservicios" {
  for_each             = toset(var.microservicios)
  name                 = "smartlogix-${each.key}-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # sin esto cuando terraform intente borrar los ecr con las imagenes dentro aws le dirá que no se pueden borrar porque dentro de los ecr hay contenido, esto soluciona eso.
}
