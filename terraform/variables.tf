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

variable "sparc_portal_urls" {}

# Cognito sender for the users2 pool. null = the region's SES mail-from
# address (dev); prod sets support@pennsieve.io + its SES configuration set.
variable "cognito_from_email_address" {
  type    = string
  default = null
}

variable "ses_configuration_set" {
  type    = string
  default = null
}

locals {
  pennsieve_app_url = "https://app.${var.domain_name}"
  pennsieve_discover_url = "https://discover.${var.domain_name}"
  domain_name = data.terraform_remote_state.account.outputs.domain_name
  hosted_zone = data.terraform_remote_state.account.outputs.public_hosted_zone_id

  common_tags = {
    aws_account      = var.aws_account
    aws_region       = data.aws_region.current_region.name
    environment_name = var.environment_name
  }
}