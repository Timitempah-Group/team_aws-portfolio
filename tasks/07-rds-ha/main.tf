terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "tasks/07-rds-ha/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Project     = "aws-portfolio"
      Task        = "07-rds-ha"
      Owner       = "senate-adeiza"
      Environment = "portfolio"
    }
  }
}

locals {
  vpc_id              = "vpc-06473c7fde6e7d405"
  isolated_subnet_ids = ["subnet-0284d4d18c33ed039", "subnet-08ce1e55ec1879ee2"]
}

# --- DB Subnet Group ---
resource "aws_db_subnet_group" "portfolio" {
  name       = "portfolio-db-subnet-group"
  subnet_ids = local.isolated_subnet_ids
}

# --- Security Group for RDS ---
resource "aws_security_group" "rds" {
  name   = "portfolio-rds-sg"
  vpc_id = local.vpc_id

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

# --- RDS Primary Instance with Multi-AZ ---
resource "aws_db_instance" "primary" {
  identifier              = "portfolio-db-primary"
  engine                  = "postgres"
  engine_version          = "16.14"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  db_name                 = "portfoliodb"
  username                = "dbadmin"
  password                = "TempPassword123!ChangeMe"
  db_subnet_group_name    = aws_db_subnet_group.portfolio.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = true
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 1
}

# --- Read Replica ---
resource "aws_db_instance" "read_replica" {
  identifier             = "portfolio-db-read-replica"
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