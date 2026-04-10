resource "aws_db_subnet_group" "db_subnet" {
  name = "sng-smartlogix-${var.environment}"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "rds_sg" {
  name = "sg-rds-smartlogix-${var.environment}"
  vpc_id  = module.vpc.vpc_id #vpc_id si bien no fue definido por nosotros está definido como una variable del modulo de github del cual se creo la VPC

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block] 
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "databases" {
  for_each = toset(local.microservicios)
  identifier = "rds-${each.key}-${var.environment}"
  db_name = each.key
  engine = "postgres"
  engine_version = "17.4"
  instance_class = "db.t4g.micro"
  allocated_storage = 20
  username = "admin_${each.key}"
  password = "Smartlogix2026!"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}