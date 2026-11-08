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

# Generate unique suffix for S3 query results bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for Storing Athena Query Results
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.environment}-athena-results-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "athena_results_ownership" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results_pab" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Amazon Athena Workgroup for Serverless SQL Queries
resource "aws_athena_workgroup" "primary" {
  name        = "${var.environment}-datalake-workgroup"
  description = "Primary Athena Workgroup for serverless analytics on S3 Data Lake"
  state       = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}