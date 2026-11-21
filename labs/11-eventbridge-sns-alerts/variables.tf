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
  description = "Target AWS Glue ETL job name to monitor for failures"
  type        = string
  default     = "dev-pyspark-etl-job"
}