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

variable "glue_database_name" {
  description = "Glue Data Catalog database name"
  type        = string
  default     = "dev_data_catalog_db"
}

variable "glue_table_name" {
  description = "Glue Data Catalog table name to validate"
  type        = string
  default     = "staging_records"
}