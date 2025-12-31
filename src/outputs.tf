output "id" {
  description = "The ID of this component deployment"
  value       = module.this.id
}

output "ecs_service_name" {
  description = "The name of the ECS service running the ADOT collector"
  value       = local.enabled ? aws_ecs_service.adot[0].name : null
}

output "ecs_service_arn" {
  description = "The ARN of the ECS service running the ADOT collector"
  value       = local.enabled ? aws_ecs_service.adot[0].id : null
}

output "task_definition_arn" {
  description = "The ARN of the ADOT collector task definition"
  value       = local.enabled ? aws_ecs_task_definition.adot[0].arn : null
}

output "task_role_arn" {
  description = "The ARN of the IAM role used by the ADOT collector task"
  value       = local.enabled ? aws_iam_role.task[0].arn : null
}

output "task_execution_role_arn" {
  description = "The ARN of the IAM role used for ECS task execution"
  value       = local.enabled ? aws_iam_role.task_execution[0].arn : null
}

output "security_group_id" {
  description = "The ID of the security group for the ADOT collector"
  value       = local.enabled ? aws_security_group.adot[0].id : null
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for ADOT collector logs"
  value       = local.enabled ? aws_cloudwatch_log_group.adot[0].name : null
}
