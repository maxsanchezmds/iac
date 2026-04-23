# IaC

Repositorio de infraestructura base para Smartlogix.

## Responsabilidad

Este repositorio administra plataforma compartida y contrato de despliegue, no el ciclo de release del `kong_gateway`.

Incluye:

- Networking base (VPC/subnets/NAT).
- Ingress ALB compartido.
- ECS cluster y servicios base.
- Roles IAM para ECS y CodeDeploy.
- Repositorio ECR del gateway.
- Parametros SSM de contrato bajo `/smartlogix/kong/deploy/*`.

## Flujo recomendado

1. Aplicar IaC (`environments/transversal` y `environments/main`) para dejar la plataforma lista.
2. Dejar que `kong_gateway` ejecute previews de PR y despliegues canary a produccion desde sus workflows.

## Pipeline en este repo

`iac/.github/workflows/iac-ci.yml` solo valida Terraform/Terragrunt.
