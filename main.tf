locals {
  awslogs_group         = "${var.logs_cloudwatch_group == "" ? "/ecs/${var.environment}/${var.name}" : var.logs_cloudwatch_group}"
  target_container_name = "${var.target_container_name == "" ? "${var.name}-${var.environment}" : var.target_container_name}"
  cloudwatch_alarm_name = "${var.cloudwatch_alarm_name == "" ? "${var.name}-${var.environment}" : var.cloudwatch_alarm_name}"
  merged_tags = merge(
    var.tags,
  var.cost_tags)
  # for each target group, allow ingress from the alb to ecs container port
  lb_ingress_container_ports = distinct(
    [
      for lb_target_group in var.lb_target_groups : lb_target_group.container_port
    ]
  )

  # for each target group, allow ingress from the alb to ecs healthcheck port
  # if it doesn't collide with the container ports
  lb_ingress_container_health_check_ports = tolist(
    setsubtract(
      [
        for lb_target_group in var.lb_target_groups : lb_target_group.container_health_check_port
      ],
      local.lb_ingress_container_ports,
    )
  )

}



#
# CloudWatch
#

resource "aws_cloudwatch_log_group" "main" {
  name              = local.awslogs_group
  retention_in_days = var.logs_cloudwatch_retention

  kms_key_id = var.kms_key_id

  tags = local.merged_tags
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu" {
  count = var.cloudwatch_alarm_cpu_enable && (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-cpu"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_cpu_threshold
  tags                = local.merged_tags
  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main[count.index].name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_mem" {
  count = var.cloudwatch_alarm_cpu_enable && (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-mem"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_mem_threshold
  tags                = local.merged_tags
  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main[count.index].name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu_no_lb" {
  count = var.cloudwatch_alarm_cpu_enable && ! (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-cpu"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_cpu_threshold
  tags                = local.merged_tags
  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main_no_lb[count.index].name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_mem_no_lb" {
  count = var.cloudwatch_alarm_cpu_enable && ! (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-mem"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_mem_threshold
  tags                = local.merged_tags
  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main_no_lb[count.index].name
  }
}

#
# SG - ECS
#

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-${var.name}-${var.environment}"
  description = "${var.name}-${var.environment} container security group"
  vpc_id      = var.ecs_vpc_id

  tags = local.merged_tags
}

resource "aws_security_group_rule" "app_ecs_allow_outbound" {
  description       = "All outbound"
  security_group_id = aws_security_group.ecs_sg.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_ecs_allow_https_from_alb" {
  # if we have an alb, then create security group rules for the container
  # ports
  count = var.associate_alb ? length(local.lb_ingress_container_ports) : 0

  description       = "Allow in ALB"
  security_group_id = aws_security_group.ecs_sg.id

  type                     = "ingress"
  from_port                = element(local.lb_ingress_container_ports, count.index)
  to_port                  = element(local.lb_ingress_container_ports, count.index)
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group
}

resource "aws_security_group_rule" "app_ecs_allow_health_check_from_alb" {
  # if we have an alb, then create security group rules for the container
  # health check ports
  count = var.associate_alb ? length(local.lb_ingress_container_health_check_ports) : 0

  description       = "Allow in health check from ALB"
  security_group_id = aws_security_group.ecs_sg.id

  type                     = "ingress"
  from_port                = element(local.lb_ingress_container_health_check_ports, count.index)
  to_port                  = element(local.lb_ingress_container_health_check_ports, count.index)
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group
}

resource "aws_security_group_rule" "app_ecs_allow_tcp_from_nlb" {
  count = var.associate_nlb ? length(local.lb_ingress_container_ports) : 0

  description       = "Allow in NLB"
  security_group_id = aws_security_group.ecs_sg.id

  type        = "ingress"
  from_port   = element(local.lb_ingress_container_ports, count.index)
  to_port     = element(local.lb_ingress_container_ports, count.index)
  protocol    = "tcp"
  cidr_blocks = var.nlb_subnet_cidr_blocks
}

resource "aws_security_group_rule" "app_ecs_allow_health_check_from_nlb" {
  count = var.associate_nlb ? length(local.lb_ingress_container_health_check_ports) : 0

  description       = "Allow in health check from NLB"
  security_group_id = aws_security_group.ecs_sg.id

  type        = "ingress"
  from_port   = element(local.lb_ingress_container_health_check_ports, count.index)
  to_port     = element(local.lb_ingress_container_health_check_ports, count.index)
  protocol    = "tcp"
  cidr_blocks = var.nlb_subnet_cidr_blocks
}

#
# IAM - instance (optional)
#

data "aws_iam_policy_document" "instance_role_policy_doc" {
  count = var.ecs_instance_role != "" ? 1 : 0

  statement {
    actions = [
      "ecs:DeregisterContainerInstance",
      "ecs:RegisterContainerInstance",
      "ecs:Submit*",
    ]

    resources = [var.ecs_cluster.arn]
  }

  statement {
    actions = [
      "ecs:UpdateContainerInstancesState",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:cluster"
      values   = [var.ecs_cluster.arn]
    }
  }

  statement {
    actions = [
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:StartTelemetrySession",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [aws_cloudwatch_log_group.main.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = var.ecr_repo_arns
  }
}

resource "aws_iam_role_policy" "instance_role_policy" {
  count = var.ecs_instance_role != "" ? 1 : 0

  name   = "${var.ecs_instance_role}-policy"
  role   = var.ecs_instance_role
  policy = data.aws_iam_policy_document.instance_role_policy_doc[0].json
}

#
# IAM - task
#

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_execution_role_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [aws_cloudwatch_log_group.main.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = var.ecr_repo_arns
  }
}

resource "aws_iam_role" "task_role" {
  name               = "ecs-task-role-${var.name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "task_execution_role" {
  count = var.ecs_use_fargate ? 1 : 0

  name               = "ecs-task-execution-role-${var.name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_execution_role_policy" {
  count = var.ecs_use_fargate ? 1 : 0

  name   = "${aws_iam_role.task_execution_role[0].name}-policy"
  role   = aws_iam_role.task_execution_role[0].name
  policy = data.aws_iam_policy_document.task_execution_role_policy_doc.json
}

#
# ECS
#

data "aws_region" "current" {
}
module "ecs_task_definition_main" {
  source                   = "github.com/unifio/terraform-aws-ecs-task-definition"
  requires_compatibilities = compact([var.ecs_use_fargate ? "FARGATE" : ""])
  cpu                      = var.ecs_use_fargate ? var.fargate_task_cpu : ""
  memory                   = var.ecs_use_fargate ? var.fargate_task_memory : ""
  execution_role_arn       = join("", aws_iam_role.task_execution_role.*.arn)
  task_role_arn            = aws_iam_role.task_role.arn
  ipc_mode                 = var.ecs_use_fargate ? null : ""
  pid_mode                 = var.ecs_use_fargate ? null : ""
  cpu_container            = var.fargate_task_cpu
  family                   = var.family
  image                    = var.container_image
  name                     = "${var.name}-${var.environment}"
  memory_container         = var.fargate_task_memory
  mountPoints              = var.mountPoints
  portMappings             = var.portMappings
  placement_constraints    = var.placement_constraints
  volumes                  = var.volumes
  tags                     = var.tags
  cost_tags                = var.cost_tags
  command                  = var.command
  network_mode             = "awsvpc"

  logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = local.awslogs_group,
      awslogs-region        = data.aws_region.current.name,
      awslogs-stream-prefix = "${var.name}-ecs"
    }
  }
  workingDirectory = "/"
  dockerLabels     = var.cost_tags
}

# Create a data source to pull the latest active revision from
data "aws_ecs_task_definition" "main" {
  task_definition = module.aws_ecs_task_definition.family
  depends_on      = [module.aws_ecs_task_definition] # ensures at least one task def exists
}

locals {
  ecs_service_launch_type = var.ecs_use_fargate ? "FARGATE" : "EC2"

  ecs_service_ordered_placement_strategy = {
    EC2 = [
      {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
      },
      {
        type  = "spread"
        field = "instanceId"
      },
    ]
    FARGATE = []
  }

  ecs_service_placement_constraints = {
    EC2 = [
      {
        type = "distinctInstance"
      },
    ]
    FARGATE = []
  }

  ecs_service_agg_security_groups = compact(concat(list(aws_security_group.ecs_sg.id), var.additional_security_group_ids))
}

resource "aws_ecs_service" "main" {
  name    = var.name
  cluster = var.ecs_cluster.arn

  launch_type = local.ecs_service_launch_type
  tags        = local.merged_tags
  # Use latest active revision
  task_definition = "${module.aws_ecs_task_definition.family}:${max(
    module.aws_ecs_task_definition.revision,
    data.aws_ecs_task_definition.main.revision,
  )}"

  desired_count                      = var.tasks_desired_count
  deployment_minimum_healthy_percent = var.tasks_minimum_healthy_percent
  deployment_maximum_percent         = var.tasks_maximum_percent

  dynamic ordered_placement_strategy {
    for_each = local.ecs_service_ordered_placement_strategy[local.ecs_service_launch_type]

    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic placement_constraints {
    for_each = local.ecs_service_placement_constraints[local.ecs_service_launch_type]

    content {
      type = placement_constraints.value.type
    }
  }

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = local.ecs_service_agg_security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic load_balancer {
    for_each = var.lb_target_groups
    content {
      container_name   = local.target_container_name
      target_group_arn = load_balancer.value.lb_target_group_arn
      container_port   = load_balancer.value.container_port
    }
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
