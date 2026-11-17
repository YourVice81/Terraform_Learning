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

# AWS Glue Workflow Container
resource "aws_glue_workflow" "data_pipeline" {
  name        = "${var.environment}-end-to-end-pipeline"
  description = "Orchestrated workflow connecting PySpark ETL transformation to Data Catalog crawler"
}

# Workflow Trigger: Starts the Glue ETL Job on Demand/Schedule
resource "aws_glue_trigger" "start_etl_job" {
  name          = "${var.environment}-start-etl-trigger"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.data_pipeline.name

  actions {
    job_name = var.glue_job_name
  }
}

# Workflow Trigger: Automatically runs Crawler AFTER ETL Job Succeeds
resource "aws_glue_trigger" "start_crawler_after_etl" {
  name          = "${var.environment}-crawler-conditional-trigger"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.data_pipeline.name

  predicate {
    conditions {
      job_name = var.glue_job_name
      state    = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = var.glue_crawler_name
  }

  depends_on = [aws_glue_trigger.start_etl_job]
}