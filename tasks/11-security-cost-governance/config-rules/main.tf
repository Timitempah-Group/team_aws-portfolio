terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "tasks/11-security-cost-governance/config-rules/terraform.tfstate"
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
      Task        = "11-security-cost-governance"
      Owner       = "senate-adeiza"
      Environment = "portfolio"
    }
  }
}

resource "aws_config_configuration_recorder" "portfolio" {
  name     = "portfolio-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "portfolio" {
  name           = "portfolio-config-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.id

  depends_on = [aws_config_configuration_recorder.portfolio]
}

resource "aws_config_configuration_recorder_status" "portfolio" {
  name       = aws_config_configuration_recorder.portfolio.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.portfolio]
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = "portfolio-config-bucket-senate-aws"
}

resource "aws_s3_bucket_public_access_block" "config_bucket" {
  bucket                  = aws_s3_bucket.config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "config" {
  name = "portfolio-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# --- Config Rule: S3 buckets must not allow public read access ---
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "portfolio-s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.portfolio]
}

# --- Config Rule: EBS volumes must be encrypted ---
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "portfolio-encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.portfolio]
}

# --- Config Rule: RDS instances must not be publicly accessible ---
resource "aws_config_config_rule" "rds_public_access_check" {
  name = "portfolio-rds-instance-public-access-check"

  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }

  depends_on = [aws_config_configuration_recorder.portfolio]
}

output "config_recorder_name" {
  value = aws_config_configuration_recorder.portfolio.name
}

output "config_bucket_name" {
  value = aws_s3_bucket.config_bucket.id
}
