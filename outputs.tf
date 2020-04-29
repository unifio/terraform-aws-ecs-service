output "ecs_security_group_id" {
  description = "Security Group ID assigned to the ECS tasks."
  value       = aws_security_group.ecs_sg.id
}

output "task_execution_role_arn" {
  description = "The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume."
  value       = join("", aws_iam_role.task_execution_role.*.arn)
}

output "task_execution_role_name" {
  description = "The name of the task execution role that the Amazon ECS container agent and the Docker daemon can assume."
  value       = join("", aws_iam_role.task_execution_role.*.name)
}

output "task_role_arn" {
  description = "The ARN of the IAM role assumed by Amazon ECS container tasks."
  value       = aws_iam_role.task_role.arn
}

output "task_role_name" {
  description = "The name of the IAM role assumed by Amazon ECS container tasks."
  value       = aws_iam_role.task_role.name
}

output "task_role" {
  description = "The IAM role object assumed by Amazon ECS container tasks."
  value       = aws_iam_role.task_role
}

output "task_execution_role" {
  description = "The role object of the task execution role that the Amazon ECS container agent and the Docker daemon can assume."
  value       = aws_iam_role.task_execution_role
}

output "task_definition_arn" {
  description = "Full ARN of the Task Definition (including both family and revision)."
  value       = module.ecs_task_definition_main.arn
}

output "task_definition_family" {
  description = "The family of the Task Definition."
  value       = module.ecs_task_definition_main.family
}

output "task_definition_revision" {
  description = "The revision of the task in a particular family"
  value       = module.ecs_task_definition_main.revision
}

output "task_container_definitions" {
  description = "A list of container definitions in JSON format that describe the different containers that make up your task"
  value       = module.ecs_task_definition_main.container_definitions
}

output "awslogs_group" {
  description = "Name of the CloudWatch Logs log group containers should use."
  value       = local.awslogs_group
}

output "awslogs_group_arn" {
  description = "ARN of the CloudWatch Logs log group containers should use."
  value       = aws_cloudwatch_log_group.main.arn
}

output "instance_role_policy" {
  description = "ARN of the Instance Role Policy"
  value       = join("", aws_iam_role_policy.instance_role_policy.*.id)
}

output "aws_ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}
output "aws_ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_service.main.cluster
}
