terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "tasks/04-asg-web-tier/terraform.tfstate"
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
      Task        = "04-asg-web-tier"
      Owner       = "senate-adeiza"
      Environment = "portfolio"
    }
  }
}

module "web_tier" {
  source              = "../../modules/web-tier"
  vpc_id              = "vpc-06473c7fde6e7d405"
  public_subnet_ids   = ["subnet-06284630cc4771c0a", "subnet-05c17df191c7d45d5"]
  private_subnet_ids  = ["subnet-025db857ef2c39efc", "subnet-064235117b1fc9794"]
}

output "alb_dns_name" {
  value = module.web_tier.alb_dns_name
}
