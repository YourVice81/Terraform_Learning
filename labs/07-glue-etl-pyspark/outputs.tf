output "etl_bucket_name" {
  description = "S3 bucket for Glue scripts and output"
  value       = aws_s3_bucket.etl_bucket.id
}

output "glue_job_name" {
  description = "Name of the provisioned Glue PySpark Job"
  value       = aws_glue_job.etl_job.name
}