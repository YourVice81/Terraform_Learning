terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "yur-life-terraform-test-bucket-9926" # Make sure to change this if needed to be unique!
  
  tags = {
    Environment = "Learning"
    ManagedBy   = "Terraform"
  }
}