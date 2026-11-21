output "data_quality_ruleset_name" {
  description = "Name of the provisioned AWS Glue Data Quality ruleset"
  value       = aws_glue_data_quality_ruleset.pipeline_quality_gate.name
}

output "data_quality_ruleset_arn" {
  description = "ARN of the provisioned AWS Glue Data Quality ruleset"
  value       = aws_glue_data_quality_ruleset.pipeline_quality_gate.arn
}