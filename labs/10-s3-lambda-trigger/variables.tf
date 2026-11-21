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

variable "glue_workflow_name" {
  description = "Name of the AWS Glue Workflow from Lab 09"
  type        = string
  default     = "dev-end-to-end-pipeline"
}