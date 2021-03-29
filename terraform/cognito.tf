resource "aws_cognito_user_pool" "cognito_user_pool" {
  name = "${var.environment_name}-${var.service_name}-user-pool-${data.terraform_remote_state.region.outputs.aws_region_shortname}"

  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"
  username_attributes      = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  device_configuration {
    device_only_remembered_on_user_prompt = true
  }

  software_token_mfa_configuration {
    enabled = true
  }

  username_configuration {
    case_sensitive = false
  }
}

resource "aws_cognito_user_group" "participants_cognito_user_group" {
  name         = "${var.environment_name}-${var.service_name}-participants-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  description  = "Cognito user group to distinguish participant users"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
}

// TODO: do we need hosted domains?
resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
  domain       = "${var.environment_name}-${var.service_name}-pennsieve-users-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  // TODO add -use1 suffix
  name                         = "${var.environment_name}-${var.service_name}-app-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                 = aws_cognito_user_pool.cognito_user_pool.id
  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows          = ["ADMIN_NO_SRP_AUTH"]
  read_attributes              = ["email"]
  write_attributes             = ["email"]
}

resource "aws_cognito_user_pool_ui_customization" "cognito_ui_customization" {
  client_id    = aws_cognito_user_pool_client.cognito_user_pool_client.id
  css          = file("${path.module}/cognito_ui.css")
  user_pool_id = aws_cognito_user_pool_domain.cognito_user_pool_domain.user_pool_id
}

resource "aws_cognito_user_pool" "cognito_token_pool" {
  name = "${var.environment_name}-${var.service_name}-token-pool-${data.terraform_remote_state.region.outputs.aws_region_shortname}"

  mfa_configuration = "OFF"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  device_configuration {
    device_only_remembered_on_user_prompt = true
  }

  password_policy {
    minimum_length    = 36
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  username_configuration {
    case_sensitive = false
  }
}

resource "aws_cognito_user_group" "tokens_cognito_user_group" {
  name         = "${var.environment_name}-${var.service_name}-tokens-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id = aws_cognito_user_pool.cognito_token_pool.id
}

// TODO: do we need hosted domains
resource "aws_cognito_user_pool_domain" "cognito_token_pool_domain" {
  domain       = "${var.environment_name}-${var.service_name}-pennsieve-tokens-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id = aws_cognito_user_pool.cognito_token_pool.id
}

resource "aws_cognito_user_pool_client" "cognito_token_pool_client" {
  name                         = "${var.environment_name}-${var.service_name}-app-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                 = aws_cognito_user_pool.cognito_token_pool.id
  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows          = ["USER_PASSWORD_AUTH"]
}