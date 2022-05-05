variable "aws_account" {}

variable "aws_region" {}

variable "environment_name" {}

variable "service_name" {}

variable "vpc_name" {}

variable "domain_name" {}

# Postgres
variable "pennsieve_postgres_host" {}

variable "pennsieve_postgres_db" {
  default = "pennsieve_postgres"
}

variable "orcid_client_id" {}

variable "orcid_client_secret" {}

variable "orcid_oidc_issuer" {}

variable "sparc_portal_redirect" {}

variable "sparc_portal_heroku_redirect" {}

locals {
  pennsieve_app_url = "https://app.${var.domain_name}"
}
