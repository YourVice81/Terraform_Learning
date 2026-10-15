variable "aws_region" {
  type        = string
  description = "Target AWS region for data lake deployment"
  default     = "us-west-2"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, prod)"
  default     = "dev"
}