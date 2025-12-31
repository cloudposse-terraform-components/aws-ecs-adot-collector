# Component: `ecs-adot-collector`

This component deploys the AWS Distro for OpenTelemetry (ADOT) collector as an ECS Fargate service. It collects metrics from ECS tasks and forwards them to Amazon Managed Prometheus for visualization in Grafana.

## Usage

**Stack Level**: Regional

This component is the ECS counterpart to the EKS Prometheus scraper/Promtail setup for Grafana monitoring. It runs the ADOT collector as a Fargate task that:

- Scrapes Prometheus metrics from ECS services via service discovery
- Collects ECS container metrics
- Forwards all metrics to Amazon Managed Prometheus

### Prerequisites

- An ECS cluster deployed via the `ecs` component
- Amazon Managed Prometheus workspace deployed via the `managed-prometheus/workspace` component
- VPC with private subnets

### Example Configuration

```yaml
components:
  terraform:
    ecs-adot-collector:
      vars:
        enabled: true
        name: ecs-adot-collector
        # ADOT collector image
        adot_image: "public.ecr.aws/aws-observability/aws-otel-collector:latest"
        # Task resources
        task_cpu: 256
        task_memory: 512
        desired_count: 1
        # Logging
        log_retention_days: 30
        # Prometheus scraping configuration
        scrape_interval: "30s"
        # ECS service discovery - discover and scrape all ECS tasks
        ecs_service_discovery_enabled: true
        # Network configuration
        assign_public_ip: false
        # Dependencies - looked up from current stack
        prometheus_workspace_endpoint: !terraform.state prometheus workspace_endpoint
        ecs_cluster_name: !terraform.state ecs/cluster cluster_name
        vpc_id: !terraform.state vpc vpc_id
        subnet_ids: !terraform.state vpc private_subnet_ids
```

### Custom Scrape Configurations

You can add additional scrape targets beyond ECS service discovery:

```yaml
vars:
  scrape_configs:
    - job_name: "custom-app"
      targets:
        - "app.internal:9090"
      metrics_path: "/metrics"
      scrape_interval: "15s"
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0, < 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0, < 6.0.0 |

## Resources

| Name | Type |
|------|------|
| aws_cloudwatch_log_group.adot | resource |
| aws_ecs_service.adot | resource |
| aws_ecs_task_definition.adot | resource |
| aws_iam_role.task | resource |
| aws_iam_role.task_execution | resource |
| aws_iam_role_policy.ecs_service_discovery | resource |
| aws_iam_role_policy_attachment.prometheus_remote_write | resource |
| aws_iam_role_policy_attachment.task_execution | resource |
| aws_security_group.adot | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| adot_image | The ADOT collector container image | `string` | `"public.ecr.aws/aws-observability/aws-otel-collector:latest"` | no |
| assign_public_ip | Assign public IP to the ADOT collector task (set to false for private subnets) | `bool` | `false` | no |
| desired_count | Number of ADOT collector tasks to run | `number` | `1` | no |
| ecs_cluster_name | The name of the ECS cluster to deploy the ADOT collector to | `string` | n/a | yes |
| ecs_service_discovery_enabled | Enable ECS service discovery for Prometheus scraping | `bool` | `true` | no |
| log_retention_days | CloudWatch log retention in days | `number` | `30` | no |
| prometheus_workspace_endpoint | The Amazon Managed Prometheus workspace endpoint URL for remote write | `string` | n/a | yes |
| region | AWS Region | `string` | n/a | yes |
| scrape_configs | Additional Prometheus scrape configurations for specific targets | `list(object)` | `[]` | no |
| scrape_interval | Prometheus scrape interval | `string` | `"30s"` | no |
| security_group_ids | Additional security group IDs to attach to the ADOT collector task | `list(string)` | `[]` | no |
| subnet_ids | List of subnet IDs for the ADOT collector task | `list(string)` | n/a | yes |
| task_cpu | CPU units for the ADOT collector task | `number` | `256` | no |
| task_memory | Memory (MiB) for the ADOT collector task | `number` | `512` | no |
| vpc_id | VPC ID where the ECS cluster is deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudwatch_log_group_name | The name of the CloudWatch log group for ADOT collector logs |
| ecs_service_arn | The ARN of the ECS service running the ADOT collector |
| ecs_service_name | The name of the ECS service running the ADOT collector |
| id | The ID of this component deployment |
| security_group_id | The ID of the security group for the ADOT collector |
| task_definition_arn | The ARN of the ADOT collector task definition |
| task_execution_role_arn | The ARN of the IAM role used for ECS task execution |
| task_role_arn | The ARN of the IAM role used by the ADOT collector task |

## References

- [AWS Distro for OpenTelemetry](https://aws-otel.github.io/)
- [Amazon Managed Prometheus](https://docs.aws.amazon.com/prometheus/)
- [cloudposse-terraform-components](https://github.com/orgs/cloudposse-terraform-components/repositories)
