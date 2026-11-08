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

# S3 Bucket for Glue ETL Scripts and Data Output
resource "aws_s3_bucket" "etl_bucket" {
  bucket        = "${var.environment}-glue-etl-${random_id.suffix.hex}"
  force_destroy = true
}

# Upload PySpark Script to S3
resource "aws_s3_object" "script" {
  bucket = aws_s3_bucket.etl_bucket.id
  key    = "scripts/etl_transform.py"
  source = "${path.module}/etl_script.py"
  etag   = filemd5("${path.module}/etl_script.py")
}

# IAM Role for AWS Glue Service Execution
resource "aws_iam_role" "glue_etl_role" {
  name = "${var.environment}-glue-etl-role"

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

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_etl_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "s3_etl_access" {
  name = "${var.environment}-glue-s3-access"
  role = aws_iam_role.glue_etl_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.etl_bucket.arn,
        "${aws_s3_bucket.etl_bucket.arn}/*"
      ]
    }]
  })
}

# AWS Glue Job Definition
resource "aws_glue_job" "etl_job" {
  name              = "${var.environment}-pyspark-etl-job"
  role_arn          = aws_iam_role.glue_etl_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.etl_bucket.id}/scripts/etl_transform.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language" = "python"
  }
}