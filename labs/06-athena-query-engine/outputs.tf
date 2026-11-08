output "athena_workgroup_name" {
  description = "Name of the provisioned Athena Workgroup"
  value       = aws_athena_workgroup.primary.id
}

output "athena_results_bucket" {
  description = "S3 bucket storing Athena query results"
  value       = aws_s3_bucket.athena_results.id
}