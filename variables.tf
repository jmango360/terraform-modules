variable "name" {
  description = "ECS name"
  type        = string
}

variable "environment" {
  description = "Tag environment"
  type        = string
}

variable "workload" {
  description = "Tag Workload"
  type        = string
}

variable "product" {
  description = "Tag Product"
  type        = string
}

variable "customer" {
  description = "Customer"
  type        = string
}

variable "cloudwatch_log_retention" {
  description = "ECS log retention"
  type        = number
  default     = 1
}

variable "task_definition_type" {
  description = "Task type (FARGATE/EC2)"
  type        = string
  default     = "FARGATE"
}

variable "task_container_image" {
  description = "Docker image"
  type        = string
  default     = "nginx:latest"
}

variable "task_container_cpu" {
  description = "Container CPU limit"
  type        = number
  default     = 256
}

variable "task_container_memory" {
  description = "Container Memory limit"
  type        = number
  default     = 512
}

variable "task_container_port" {
  description = "Container Port"
  type        = number
  default     = 80
}

variable "ecs_execution_role" {
  description = "ECS Execution role"
  type        = string
  default     = "arn:aws:iam::611515463420:role/ecsTaskExecutionRole"
}

variable "alb_listener_arn" {
  description = "Application Load Balancer"
  type        = string
  default     = ""
}

variable "ecs_cluster" {
  description = "ECS cluster object for this task."
  type = object({
    arn  = string
    name = string
  })
}

variable "platform_version" {
  description = "ECS Platform"
  type        = string
  default     = "1.4.0"
}

variable "ecs_vpc_id" {
  description = "VPC ID to be used by ECS."
  type        = string
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for the ECS tasks."
  type        = list(string)
}

variable "task_assign_public_ip" {
  description = "ECS Assign public IP"
  type        = bool
  default     = false
}

variable "deregistration_delay" {
  description = "Task deregistration delay"
  type        = number
  default     = 30
}

variable "route53_zone_id" {
  description = "Route53 zone id"
  type        = string
}

variable "alb_security_group" {
  description = "ALB Security group"
  type        = list(string)
}

variable "task_desired_count" {
  description = "Number of running tasks"
  type        = number
  default     = 1
}

variable "deployment_maximum_percent" {
  description = "Maximum number of running tasks"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum number of running tasks"
  type        = number
  default     = 100
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period"
  type        = number
  default     = 30
}

variable "alb_alias_name" {
  description = "ALB Name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB Zone ID"
  type        = string
}

variable "alb_evaluate_target_health" {
  description = "ALB Evaluate Target Health"
  type        = string
  default     = false
}