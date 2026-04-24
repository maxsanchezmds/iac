locals {
  create_postgres         = length(var.postgres_services) > 0
  postgres_database_names = { for service in var.postgres_services : service => replace(service, "-", "_") }
  postgres_usernames      = { for service in var.postgres_services : service => "admin_${replace(service, "-", "_")}" }
}

resource "aws_db_subnet_group" "db_subnet" {
  count      = local.create_postgres ? 1 : 0
  name       = "sng-smartlogix-${var.environment}"
  subnet_ids = var.private_subnets
}

resource "aws_security_group" "rds_sg" {
  count  = local.create_postgres ? 1 : 0
  name   = "rds-sg-smartlogix-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "databases" {
  for_each               = toset(var.postgres_services)
  identifier             = "rds-${each.key}-${var.environment}"
  db_name                = local.postgres_database_names[each.key]
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  username               = local.postgres_usernames[each.key]
  password               = var.postgres_passwords[each.key]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet[0].name
  vpc_security_group_ids = [aws_security_group.rds_sg[0].id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}

resource "aws_ssm_parameter" "postgres_connection_url" {
  for_each = aws_db_instance.databases

  name        = "/smartlogix/${var.environment}/${each.key}/postgres_url"
  description = "PostgreSQL connection URL para el microservicio ${each.key}"
  type        = "SecureString"
  value       = "postgresql://${local.postgres_usernames[each.key]}:${urlencode(var.postgres_passwords[each.key])}@${each.value.address}:${each.value.port}/${local.postgres_database_names[each.key]}"
}
