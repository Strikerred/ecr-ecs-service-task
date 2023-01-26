variable "aws_region" {
  description = "AWS Region in which this service will be deployed"
  type        = string
}

variable "environment" {
  description = "Environment for which this service will be deployed"
  type        = string
}

variable "department" {
  description = "Department responsible for this service"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "secret_name" {
  type        = string
  description = "Secret name within AWS Secrets Manager"
}

variable "connections" {
  type        = list(any)
  description = "List of connections map"
}
