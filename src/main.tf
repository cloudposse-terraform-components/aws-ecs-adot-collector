locals {
  enabled = module.this.enabled

  # Build the ADOT collector configuration from template
  otel_config = templatefile("${path.module}/templates/otel-config.yaml.tftpl", {
    region                        = var.region
    scrape_interval               = var.scrape_interval
    ecs_service_discovery_enabled = var.ecs_service_discovery_enabled
    scrape_configs                = var.scrape_configs
    prometheus_endpoint           = var.prometheus_workspace_endpoint
  })
}

# CloudWatch Log Group for ADOT collector logs
resource "aws_cloudwatch_log_group" "adot" {
  count = local.enabled ? 1 : 0

  name              = "/ecs/${module.this.id}"
  retention_in_days = var.log_retention_days
  tags              = module.this.tags
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "task_execution" {
  count = local.enabled ? 1 : 0

  name = "${module.this.id}-execution"
  tags = module.this.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (ADOT collector runtime)
resource "aws_iam_role" "task" {
  count = local.enabled ? 1 : 0

  name = "${module.this.id}-task"
  tags = module.this.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Prometheus Remote Write policy
resource "aws_iam_role_policy_attachment" "prometheus_remote_write" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.task[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}

# ECS service discovery policy for listing tasks
resource "aws_iam_role_policy" "ecs_service_discovery" {
  count = local.enabled && var.ecs_service_discovery_enabled ? 1 : 0

  name = "${module.this.id}-ecs-discovery"
  role = aws_iam_role.task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:ListServices",
          "ecs:DescribeTasks",
          "ecs:DescribeServices",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTaskDefinition",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Security Group for ADOT collector
resource "aws_security_group" "adot" {
  count = local.enabled ? 1 : 0

  name        = module.this.id
  description = "Security group for ADOT collector"
  vpc_id      = var.vpc_id
  tags        = module.this.tags

  # Allow outbound traffic to Prometheus workspace and ECS tasks
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "adot" {
  count = local.enabled ? 1 : 0

  family                   = module.this.id
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution[0].arn
  task_role_arn            = aws_iam_role.task[0].arn
  tags                     = module.this.tags

  container_definitions = jsonencode([
    {
      name      = "adot-collector"
      image     = var.adot_image
      essential = true

      environment = [
        {
          name  = "AOT_CONFIG_CONTENT"
          value = local.otel_config
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.adot[0].name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "adot"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "/healthcheck"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "adot" {
  count = local.enabled ? 1 : 0

  name            = module.this.id
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.adot[0].arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  tags            = module.this.tags

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = concat([aws_security_group.adot[0].id], var.security_group_ids)
    assign_public_ip = var.assign_public_ip
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
