output "datalake_bucket_name" {
	value       = aws_s3_bucket.datalake.id
	description = "The target S3 Data Lake bucket created for Glue crawling."
}

output "glue_catalog_database_name" {
	value       = aws_glue_catalog_database.datalake_db.name
	description = "The name of the Glue Catalog Database."
}

output "glue_crawler_name" {
	value       = aws_glue_crawler.s3_crawler.name
	description = "The name of the provisioned Glue Crawler."
}

output "glue_crawler_role_arn" {
	value       = aws_iam_role.glue_crawler_role.arn
	description = "ARN of the IAM role used by AWS Glue Crawler."
}
