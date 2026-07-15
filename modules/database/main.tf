variable "name_prefix" {
  default = "portfolio"
}

variable "vpc_id" {}
variable "isolated_subnet_ids" {
  type = list(string)
}
variable "db_password" {
  sensitive = true
}

resource "aws_db_subnet_group" "portfolio" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.isolated_subnet_ids
}

resource "aws_security_group" "rds" {
  name   = "${var.name_prefix}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "primary" {
  identifier              = "${var.name_prefix}-db-primary"
  engine                  = "postgres"
  engine_version          = "16.14"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  db_name                 = "portfoliodb"
  username                = "dbadmin"
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.portfolio.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = true
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 1
}

resource "aws_db_instance" "read_replica" {
  identifier             = "${var.name_prefix}-db-read-replica"
  replicate_source_db    = aws_db_instance.primary.identifier
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

output "primary_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "read_replica_endpoint" {
  value = aws_db_instance.read_replica.endpoint
}
