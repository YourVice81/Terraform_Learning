terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

# AWS Glue Data Quality Ruleset
resource "aws_glue_catalog_database" "dq_db" {
  name = "${var.environment}_dq_db_${random_id.suffix.hex}"
}

resource "aws_glue_catalog_table" "dq_table" {
  name          = "${var.environment}_dq_table_${random_id.suffix.hex}"
  database_name = aws_glue_catalog_database.dq_db.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${var.environment}-dq-target-${random_id.suffix.hex}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "id"
      type = "string"
    }
  }
}

resource "aws_glue_data_quality_ruleset" "pipeline_quality_gate" {
  name        = "${var.environment}-pipeline-dq-ruleset-${random_id.suffix.hex}"
  description = "Automated data quality checks for cataloged pipeline output"

  target_table {
    database_name = aws_glue_catalog_database.dq_db.name
    table_name    = aws_glue_catalog_table.dq_table.name
  }

  ruleset = replace(<<-DQDL
    Rules = [
      RowCount > 0,
      IsComplete "id",
      IsUnique "id"
    ]
  DQDL
  , "\r", "")
}