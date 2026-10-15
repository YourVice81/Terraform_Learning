terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = "yur-life-datalake-${var.environment}-${random_id.bucket_suffix.hex}"
}

# 1. S3 Data Lake Bucket
resource "aws_s3_bucket" "datalake" {
  bucket        = local.bucket_name
  force_destroy = true # Allows clean terraform destroy during labs

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Cloud Data Engineering Roadmap"
  }
}

# 2. Enforce Ownership Controls
resource "aws_s3_bucket_ownership_controls" "datalake_ownership" {
  bucket = aws_s3_bucket.datalake.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 3. Block Public Access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "datalake_public_access" {
  bucket                  = aws_s3_bucket.datalake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Create Initial Partitioned Landing Zone Prefix (Raw Layer)
resource "aws_s3_object" "raw_landing_zone" {
  bucket = aws_s3_bucket.datalake.id
  key    = "raw/year=2026/month=10/"
}