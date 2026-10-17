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

# 1. Target S3 Data Lake Bucket
resource "aws_s3_bucket" "datalake" {
	bucket        = local.bucket_name
	force_destroy = true

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

# 4. Create Initial Raw Landing Zone Prefix
resource "aws_s3_object" "raw_landing_zone" {
	bucket = aws_s3_bucket.datalake.id
	key    = "raw/year=2026/month=10/"
}

# 5. AWS Glue Catalog Database
resource "aws_glue_catalog_database" "datalake_db" {
	name        = "${var.environment}_datalake_catalog"
	description = "Glue Catalog Database for partitioned S3 data lake"
}

# 6. IAM Role for AWS Glue Service
resource "aws_iam_role" "glue_crawler_role" {
	name = "${var.environment}-glue-crawler-role"

	assume_role_policy = jsonencode({
		Version = "2012-10-17"
		Statement = [
			{
				Action = "sts:AssumeRole"
				Effect = "Allow"
				Principal = {
					Service = "glue.amazonaws.com"
				}
			}
		]
	})

	tags = {
		Environment = var.environment
		ManagedBy   = "Terraform"
		Project     = "Cloud Data Engineering Roadmap"
	}
}

# 7. Attach AWS Managed Policy for Glue Service
resource "aws_iam_role_policy_attachment" "glue_service_attach" {
	role       = aws_iam_role.glue_crawler_role.name
	policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# 8. Inline Policy for S3 Data Lake Read Access
resource "aws_iam_role_policy" "glue_s3_read_policy" {
	name = "${var.environment}-glue-s3-read-policy"
	role = aws_iam_role.glue_crawler_role.id

	policy = jsonencode({
		Version = "2012-10-17"
		Statement = [
			{
				Effect = "Allow"
				Action = [
					"s3:GetObject",
					"s3:PutObject",
					"s3:ListBucket"
				]
				Resource = [
					aws_s3_bucket.datalake.arn,
					"${aws_s3_bucket.datalake.arn}/*"
				]
			}
		]
	})
}

# 9. AWS Glue Crawler
resource "aws_glue_crawler" "s3_crawler" {
	database_name = aws_glue_catalog_database.datalake_db.name
	name          = "${var.environment}-s3-datalake-crawler"
	role          = aws_iam_role.glue_crawler_role.arn

	s3_target {
		path = "s3://${aws_s3_bucket.datalake.bucket}/raw/"
	}

	depends_on = [aws_s3_object.raw_landing_zone]

	tags = {
		Environment = var.environment
		ManagedBy   = "Terraform"
		Project     = "Cloud Data Engineering Roadmap"
	}
}
