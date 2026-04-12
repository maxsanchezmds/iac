resource "aws_db_subnet_group" "db_subnet" {
  name       = "sng-smartlogix-${var.environment}"
  subnet_ids = var.private_subnets
}

resource "aws_security_group" "rds_sg" {
  name   = "sg-rds-smartlogix-${var.environment}"
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
  for_each               = toset(var.microservicios)
  identifier             = "rds-${each.key}-${var.environment}"
  db_name                = each.key
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  username               = "admin_${each.key}"
  password               = var.db_passwords[each.key]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}