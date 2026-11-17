output "glue_workflow_name" {
  description = "Name of the provisioned AWS Glue Workflow"
  value       = aws_glue_workflow.data_pipeline.name
}

output "workflow_triggers" {
  description = "Active triggers orchestrating the workflow"
  value       = [aws_glue_trigger.start_etl_job.name, aws_glue_trigger.start_crawler_after_etl.name]
}