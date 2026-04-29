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

## Acceso privado a bases de datos con AWS Client VPN

El acceso administrativo a PostgreSQL se realiza sin exponer RDS a Internet. El stack `environments/main` puede crear un AWS Client VPN asociado a las subredes privadas de la VPC compartida y autorizar su Security Group contra el Security Group de RDS en el puerto `5432`.

### Prerrequisitos

- Importar en ACM un certificado de servidor para Client VPN.
- Importar en ACM la CA raiz que firma los certificados de cliente.
- Emitir un certificado de cliente por desarrollador o por dispositivo, fuera de Terraform.

No se deben generar llaves privadas ni certificados de cliente dentro de Terraform, porque quedarían persistidos en el state.

### Activacion desde GitHub Actions

El deploy de infraestructura se ejecuta desde `.github/workflows/iac-deploy.yml` con `workflow_dispatch`.

Configurar estas repository variables:

```text
CLIENT_VPN_ENABLED=true
CLIENT_VPN_SERVER_CERTIFICATE_ARN=arn:aws:acm:us-east-1:<account-id>:certificate/<server-certificate-id>
CLIENT_VPN_ROOT_CERTIFICATE_ARN=arn:aws:acm:us-east-1:<account-id>:certificate/<client-root-ca-certificate-id>
CLIENT_VPN_CLIENT_CIDR_BLOCK=172.16.0.0/22
```

El workflow usa los secrets existentes:

```text
AWS_ACCESS_KEY
AWS_ACCESS_KEY_SECRET
MONGODB_INVENTARIO_URI
```

Luego ejecutar manualmente el workflow `IaC Deploy` desde GitHub Actions. El input `apply_transversal` permite decidir si se aplica tambien el stack transversal antes de `main`.

### Activacion local opcional

Desde `iac/environments/main`, aplicar con las variables de entorno:

```bash
export CLIENT_VPN_ENABLED=true
export CLIENT_VPN_SERVER_CERTIFICATE_ARN=arn:aws:acm:us-east-1:<account-id>:certificate/<server-certificate-id>
export CLIENT_VPN_ROOT_CERTIFICATE_ARN=arn:aws:acm:us-east-1:<account-id>:certificate/<client-root-ca-certificate-id>
export CLIENT_VPN_CLIENT_CIDR_BLOCK=172.16.0.0/22

terragrunt apply
```

El CIDR de clientes VPN no debe solaparse con la VPC ni con las redes locales habituales de los desarrolladores.

### Configuracion del cliente

Obtener el endpoint:

```bash
terragrunt output client_vpn_endpoint_id
```

Exportar la configuracion:

```bash
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id <cvpn-endpoint-id> \
  --output text > smartlogix-main.ovpn
```

Cada desarrollador debe usar su propio certificado y llave de cliente junto con el archivo `.ovpn`. Una vez conectado al VPN, pgAdmin/DBeaver/DataGrip debe apuntar al endpoint privado de RDS con SSL habilitado.
