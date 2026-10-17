variable "aws_region" {
	type        = string
	description = "Target AWS region"
	default     = "us-west-2"
}

variable "environment" {
	type        = string
	description = "Deployment environment"
	default     = "dev"
}
