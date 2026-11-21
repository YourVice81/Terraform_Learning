output "landing_bucket_name" {
  description = "S3 bucket configured to emit ObjectCreated events"
  value       = aws_s3_bucket.landing_bucket.id
}

output "lambda_function_name" {
  description = "Name of the AWS Lambda trigger function"
  value       = aws_lambda_function.workflow_trigger.function_name
}