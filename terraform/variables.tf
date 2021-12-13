variable "aws_account" {}

variable "aws_region" {}

variable "environment_name" {}

variable "service_name" {}

variable "vpc_name" {}

# Postgres
variable "pennsieve_postgres_host" {}

variable "pennsieve_postgres_db" {
  default = "pennsieve_postgres"
}

locals {
  pennsieve_app_url = "${var.environment_name}" == "dev" ? "https://app.pennsieve.net" : "https://app.pennsieve.io"
}