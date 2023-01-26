terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.24.0"
    }
  }
}

module "constants" {
  source      = "git::ssh://git@bitbucket.org/YourOrganization/modules.git//modules/constants?ref=xxxxxxx"
  environment = var.environment
}

locals {
  cluster_name              = "vpn"
  secrets_keys              = ["USERNAME", "PASSWORD", "PSK"]
  launch_type               = ["EC2"]
  network_mode              = "bridge"
  cloudwatch_logs_retention = 120
  number_of_tasks           = "1"
  deploy_max_percent        = 200
  deploy_min_health_percent = 100
  placement_template_custom = ["attribute:ecs.availability-zone", "instanceId"]
}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.this.proxy_endpoint
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }
}

data "aws_secretsmanager_secret" "this" {
  name = var.secret_name
}

data "aws_ecs_cluster" "this" {
  cluster_name = local.cluster_name
}

data "aws_ecr_authorization_token" "this" {}

resource "aws_cloudwatch_log_group" "this" {
  for_each = { for connection in var.connections : connection.static_env_values.CONF => connection }

  name              = "/ecs/${each.value.static_env_values.CONF}-vpn"
  retention_in_days = local.cloudwatch_logs_retention
}

resource "docker_registry_image" "this" {
  name = "${aws_ecr_repository.this.repository_url}:latest"

  build {
    context    = "./${var.service_name}-vpn"
    dockerfile = "Dockerfile"
  }
}

resource "aws_ecr_repository" "this" {
  name                 = "${var.service_name}-vpn"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecs_task_definition" "this" {
  for_each = { for connection in var.connections : connection.static_env_values.CONF => connection }

  family                   = "${each.value.static_env_values.CONF}-vpn"
  requires_compatibilities = local.launch_type
  task_role_arn            = data.aws_iam_role.vpn_task.arn
  network_mode             = local.network_mode
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name              = var.service_name
      image             = "${aws_ecr_repository.this.repository_url}:latest"
      cpu               = 512
      memoryReservation = 512
      essential         = true
      portMappings = [
        {
          containerPort = each.value.container_host_port
          hostPort      = each.value.container_host_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this[each.value.static_env_values.CONF].name
          awslogs-region        = module.constants.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      secrets     = [for k in local.secrets_keys : { name : k, valueFrom : "${data.aws_secretsmanager_secret.this.arn}:${each.value.static_env_values.CONF}.${k}::" }]
      environment = [for k, v in each.value.static_env_values : { name : k, value : v }]
      privileged  = true
    }
  ])
}

resource "aws_ecs_service" "this" {
  for_each = { for connection in var.connections : connection.static_env_values.CONF => connection }

  cluster                            = data.aws_ecs_cluster.this.arn
  launch_type                        = local.launch_type[0]
  desired_count                      = local.number_of_tasks
  name                               = "${each.value.static_env_values.CONF}-vpn"
  force_new_deployment               = true
  task_definition                    = aws_ecs_task_definition.this[each.value.static_env_values.CONF].arn
  deployment_maximum_percent         = local.deploy_max_percent
  deployment_minimum_healthy_percent = local.deploy_min_health_percent

  dynamic "ordered_placement_strategy" {
    for_each = local.placement_template_custom
    iterator = placement
    content {
      type  = "spread"
      field = placement.value
    }
  }

  lifecycle {
    ignore_changes = [
      desired_count,
    ]
  }
}
