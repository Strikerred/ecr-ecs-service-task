data "aws_iam_role" "vpn_task" {
  name = "vpnTask"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}
