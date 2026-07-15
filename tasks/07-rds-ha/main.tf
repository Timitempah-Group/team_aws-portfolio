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

module "database" {
  source              = "../../modules/database"
  vpc_id              = "vpc-06473c7fde6e7d405"
  isolated_subnet_ids = ["subnet-0284d4d18c33ed039", "subnet-08ce1e55ec1879ee2"]
  db_password         = "TempPassword123!ChangeMe"
}

output "primary_endpoint" {
  value = module.database.primary_endpoint
}

output "read_replica_endpoint" {
  value = module.database.read_replica_endpoint
}
