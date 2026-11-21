output "sns_topic_arn" {
  description = "ARN of the SNS topic receiving Glue failure events"
  value       = aws_sns_topic.glue_failure_alerts.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule monitoring Glue job failures"
  value       = aws_cloudwatch_event_rule.glue_job_failure.name
}