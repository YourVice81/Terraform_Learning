terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
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

# S3 Bucket for Incoming Raw Data Events
resource "aws_s3_bucket" "landing_bucket" {
  bucket        = "${var.environment}-event-landing-${random_id.suffix.hex}"
  force_destroy = true
}

# Package Python Lambda Code into a ZIP Archive
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/lambda_trigger.zip"
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-s3-glue-trigger-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Basic CloudWatch Logs Policy + Permission to Start the Glue Workflow
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_glue_workflow_policy" {
  name = "${var.environment}-start-glue-workflow-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["glue:StartWorkflowRun"]
      Resource = "arn:aws:glue:${var.aws_region}:*:workflow/${var.glue_workflow_name}"
    }]
  })
}

# AWS Lambda Function
resource "aws_lambda_function" "workflow_trigger" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${var.environment}-s3-to-glue-workflow"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      GLUE_WORKFLOW_NAME = var.glue_workflow_name
    }
  }
}

# Allow S3 to Invoke the Lambda Function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3LandingBucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workflow_trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.landing_bucket.arn
}

# S3 Bucket Event Notification
resource "aws_s3_bucket_notification" "landing_notification" {
  bucket = aws_s3_bucket.landing_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.workflow_trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw-incoming/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}