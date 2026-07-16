terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "tasks/10-cicd-pipeline/terraform.tfstate"
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
      Task        = "10-cicd-pipeline"
      Owner       = "senate-adeiza"
      Environment = "portfolio"
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name = "portfolio-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_codedeploy_app" "web_tier" {
  name             = "portfolio-web-tier-app"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "web_tier" {
  app_name              = aws_codedeploy_app.web_tier.name
  deployment_group_name = "portfolio-web-tier-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn

  autoscaling_groups = ["portfolio-web-asg"]

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.web_tier.name
}

output "codedeploy_deployment_group" {
  value = aws_codedeploy_deployment_group.web_tier.deployment_group_name
}
