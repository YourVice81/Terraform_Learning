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

resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket for Data Lake Target
resource "aws_s3_bucket" "datalake_bucket" {
  bucket        = "${var.environment}-crawler-datalake-${random_id.suffix.hex}"
  force_destroy = true
}

# Glue Catalog Database
resource "aws_glue_catalog_database" "datalake_db" {
  name        = "${var.environment}_datalake_db_${random_id.suffix.hex}"
  description = "Database managed by Terraform for Glue Crawler metadata"
}

# IAM Role for AWS Glue Crawler
resource "aws_iam_role" "glue_crawler_role" {
  name = "${var.environment}-glue-crawler-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

# Attach AWS Managed Policy for Glue Service
resource "aws_iam_role_policy_attachment" "crawler_service" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom Policy for S3 Data Access
resource "aws_iam_role_policy" "crawler_s3_access" {
  name = "${var.environment}-crawler-s3-policy"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.datalake_bucket.arn,
        "${aws_s3_bucket.datalake_bucket.arn}/*"
      ]
    }]
  })
}

# AWS Glue Crawler Definition
resource "aws_glue_crawler" "datalake_crawler" {
  name          = "${var.environment}-s3-data-crawler"
  database_name = aws_glue_catalog_database.datalake_db.name
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.datalake_bucket.id}/raw-data/"
  }

  table_prefix = "raw_"
}