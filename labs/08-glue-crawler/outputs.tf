output "glue_database_name" {
  description = "Name of the Glue Catalog Database"
  value       = aws_glue_catalog_database.datalake_db.name
}

output "glue_crawler_name" {
  description = "Name of the provisioned Glue Crawler"
  value       = aws_glue_crawler.datalake_crawler.name
}

output "datalake_bucket_name" {
  description = "S3 Data Lake bucket name"
  value       = aws_s3_bucket.datalake_bucket.id
}