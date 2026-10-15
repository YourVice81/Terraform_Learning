output "datalake_bucket_name" {
  value       = aws_s3_bucket.datalake.id
  description = "The globally unique name of the S3 data lake bucket."
}

output "datalake_bucket_arn" {
  value       = aws_s3_bucket.datalake.arn
  description = "The ARN of the S3 data lake bucket for IAM policies."
}