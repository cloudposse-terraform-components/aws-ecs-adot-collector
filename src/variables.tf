variable "region" {
  type        = string
  description = "AWS Region"
}

variable "prometheus_workspace_endpoint" {
  type        = string
  description = "The Amazon Managed Prometheus workspace endpoint URL for remote write"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS cluster to deploy the ADOT collector to"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ECS cluster is deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the ADOT collector task"
}

variable "adot_image" {
  type        = string
  description = "The ADOT collector container image"
  default     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
}

variable "task_cpu" {
  type        = number
  description = "CPU units for the ADOT collector task"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Memory (MiB) for the ADOT collector task"
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Number of ADOT collector tasks to run"
  default     = 1
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

variable "scrape_interval" {
  type        = string
  description = "Prometheus scrape interval"
  default     = "30s"
}

variable "scrape_configs" {
  type = list(object({
    job_name        = string
    targets         = list(string)
    metrics_path    = optional(string, "/metrics")
    scrape_interval = optional(string, "")
  }))
  description = "Additional Prometheus scrape configurations for specific targets"
  default     = []
}

variable "ecs_service_discovery_enabled" {
  type        = bool
  description = "Enable ECS service discovery for Prometheus scraping"
  default     = true
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs to attach to the ADOT collector task"
  default     = []
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign public IP to the ADOT collector task (set to false for private subnets)"
  default     = false
}
