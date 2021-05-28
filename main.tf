locals {
  cloudwatch_log_group = "ecs/${var.environment}/${var.name}"
  domain_name          = "${var.name}.int.jmango.net"

  common_tags = {
    Name        = var.name
    Environment = var.environment
    Product     = var.product
    Customer    = var.customer
    ManagedBy   = "Terraform"
  }
}

data "aws_region" "current" {
}

#
# Cloudwatch
#
resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = local.cloudwatch_log_group
  retention_in_days = var.cloudwatch_log_retention

  tags = merge(
    local.common_tags,
    {
      Workload = "monitor"
    }
  )
}

#
# Task
#
resource "aws_ecs_task_definition" "task_definition" {
  family = var.name
  container_definitions = jsonencode(
    [
      {
        name  = var.name
        image = var.task_container_image

        essential         = true
        cpu               = var.task_container_cpu
        memoryReservation = var.task_container_memory

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = local.cloudwatch_log_group
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = var.name
          }
        }

        portMappings = [
          {
            containerPort = var.task_container_port
            hostPort      = var.task_container_port
          }
        ]
      }
    ]
  )

  requires_compatibilities = [var.task_definition_type]
  cpu                      = var.task_container_cpu
  memory                   = var.task_container_memory
  network_mode             = "awsvpc"
  execution_role_arn       = var.ecs_execution_role

  tags = merge(
    local.common_tags,
    {
      Workload = var.workload
    }
  )

  lifecycle {
    ignore_changes = [
      cpu,
      memory,
      container_definitions
    ]
  }
}

#
# Security Group
#
resource "aws_security_group" "task_sg" {
  description = "Security group for ecs task"
  vpc_id      = var.ecs_vpc_id

  ingress {
    from_port       = var.task_container_port
    to_port         = var.task_container_port
    protocol        = "tcp"
    security_groups = var.alb_security_group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#
# Service
#
resource "aws_ecs_service" "ecs_service" {
  name             = var.name
  cluster          = var.ecs_cluster_arn
  platform_version = var.platform_version
  task_definition  = aws_ecs_task_definition.task_definition.arn

  deployment_controller {
    type = "ECS"
  }

  desired_count                      = var.task_desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  propagate_tags                     = "TASK_DEFINITION"

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 100
  }

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = [aws_security_group.task_sg.id]
    assign_public_ip = var.task_assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = var.name
    container_port   = var.task_container_port
  }

  tags = merge(
    local.common_tags,
    {
      Workload = var.workload
    }
  )

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

#
# ALB Target Group
#
resource "aws_lb_target_group" "target_group" {
  name                 = "${var.environment}-${var.name}"
  port                 = var.task_container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.ecs_vpc_id
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    interval            = 15
    path                = "/"
    port                = var.task_container_port
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200,201"
  }

  tags = {
    Name        = "${var.environment}-${var.name}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = var.alb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      values = [local.domain_name]
    }
  }
}

# Route53 record
resource "aws_route53_record" "route53_record" {
  zone_id = var.route53_zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = var.alb_alias_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.alb_evaluate_target_health
  }
}
  