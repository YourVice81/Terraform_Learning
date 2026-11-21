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

# SNS Topic for Pipeline Failure Alerts
resource "aws_sns_topic" "glue_failure_alerts" {
  name = "${var.environment}-glue-pipeline-alerts-${random_id.suffix.hex}"
}

# Allow Amazon EventBridge to Publish to the SNS Topic
resource "aws_sns_topic_policy" "allow_eventbridge_publish" {
  arn = aws_sns_topic.glue_failure_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridgePublishToSNS"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "sns:Publish"
      Resource = aws_sns_topic.glue_failure_alerts.arn
    }]
  })
}

# EventBridge Rule Matching Glue Job State Changes (FAILED / ERROR / TIMEOUT)
resource "aws_cloudwatch_event_rule" "glue_job_failure" {
  name        = "${var.environment}-glue-job-failure-rule-${random_id.suffix.hex}"
  description = "Captures failed, error, or timeout state transitions for the Glue ETL job"

  event_pattern = jsonencode({
    source      = ["aws.glue"]
    detail-type = ["Glue Job State Change"]
    detail = {
      jobName = [var.glue_job_name]
      state   = ["FAILED", "ERROR", "TIMEOUT"]
    }
  })
}

# Route Matching EventBridge Events to the SNS Topic
resource "aws_cloudwatch_event_target" "send_alert_to_sns" {
  rule      = aws_cloudwatch_event_rule.glue_job_failure.name
  target_id = "SendGlueFailureToSNS"
  arn       = aws_sns_topic.glue_failure_alerts.arn
}