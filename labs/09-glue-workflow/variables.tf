variable "aws_region" {
  description = "Target AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "glue_job_name" {
  description = "Name of the existing Glue ETL job from Lab 07"
  type        = string
  default     = "dev-pyspark-etl-job"
}

variable "glue_crawler_name" {
  description = "Name of the existing Glue crawler from Lab 08"
  type        = string
  default     = "dev-s3-data-crawler"
}