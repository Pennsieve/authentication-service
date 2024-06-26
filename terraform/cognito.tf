resource "aws_cognito_user_pool" "cognito_user_pool" {
  name = "${var.environment_name}-users-${data.terraform_remote_state.region.outputs.aws_region_shortname}"

  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"
  username_attributes      = ["email"]

  email_configuration {
    email_sending_account  = "DEVELOPER"
    source_arn             = data.terraform_remote_state.region.outputs.ses_domain_identity_arn
    from_email_address     = data.terraform_remote_state.region.outputs.ses_mail_from_email_address
    reply_to_email_address = data.terraform_remote_state.region.outputs.ses_reply_to_email_address
  }

  lambda_config {
    custom_message = aws_lambda_function.cognito_custom_message_lambda.arn
  }

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

  lifecycle {
    prevent_destroy = true
  }

  schema {
    name                     = "invite_path"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  
  schema {
    name                     = "orcid"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  name                          = "${var.environment_name}-users-app-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                  = aws_cognito_user_pool.cognito_user_pool.id
  supported_identity_providers  = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Set a single write attribute. Perversely, if this list is empty, then *all*
  # attributes are writable.
  write_attributes = ["name"]
  read_attributes  = ["email"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_admin_client" {
  name                          = "${var.environment_name}-users-app-admin-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                  = aws_cognito_user_pool.cognito_user_pool.id
  supported_identity_providers  = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Set a single write attribute. Perversely, if this list is empty, then *all*
  # attributes are writable.
  write_attributes = ["name"]
  read_attributes  = ["email"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_pool" "cognito_user_pool_2" {
  name = "${var.environment_name}-users2-${data.terraform_remote_state.region.outputs.aws_region_shortname}"

  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"
  username_attributes      = ["email"]

  email_configuration {
    email_sending_account  = "DEVELOPER"
    source_arn             = data.terraform_remote_state.region.outputs.ses_domain_identity_arn
    from_email_address     = data.terraform_remote_state.region.outputs.ses_mail_from_email_address
    reply_to_email_address = data.terraform_remote_state.region.outputs.ses_reply_to_email_address
  }

  lambda_config {
    custom_message = aws_lambda_function.cognito_custom_message_lambda.arn
    user_migration = aws_lambda_function.cognito_users2_migration_lambda.arn
    post_authentication = aws_lambda_function.cognito_post_authentication_lambda.arn
    pre_sign_up = aws_lambda_function.cognito_pre_sign_up_lambda.arn
  }

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

  lifecycle {
    prevent_destroy = true
  }

  schema {
    name                     = "invite_path"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  
  schema {
    name                     = "orcid"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_identity_provider" "orcid_identity_provider" {
  user_pool_id = aws_cognito_user_pool.cognito_user_pool_2.id
  
  provider_name = "ORCID"
  provider_type = "OIDC"
  
  provider_details = {
    attributes_request_method = "GET"
    authorize_scopes = "openid"
    client_id = "${var.orcid_client_id}"
    client_secret = "${var.orcid_client_secret}"
    oidc_issuer = "${var.orcid_oidc_issuer}"
  }
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_client_2" {
  name                          = "${var.environment_name}-users2-app-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                  = aws_cognito_user_pool.cognito_user_pool_2.id
  supported_identity_providers  = ["COGNITO", "ORCID"]
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  
  callback_urls = flatten(["${local.pennsieve_app_url}", "${var.sparc_portal_urls}", "${var.environment_name}" == "dev" ? ["http://localhost:3000"] : []])
  logout_urls   = flatten(["${local.pennsieve_app_url}", "${var.sparc_portal_urls}", "${var.environment_name}" == "dev" ? ["http://localhost:3000"] : []])

  
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_scopes = ["email", "openid", "profile"]

  # Set a single write attribute. Perversely, if this list is empty, then *all*
  # attributes are writable.
  write_attributes = ["name"]
  read_attributes  = ["email"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
  domain       = "pennsieve-${var.environment_name}-users2"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool_2.id
}

resource "aws_cognito_user_pool" "cognito_token_pool" {
  name = "${var.environment_name}-client-tokens-${data.terraform_remote_state.region.outputs.aws_region_shortname}"

  mfa_configuration = "OFF"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  device_configuration {
    device_only_remembered_on_user_prompt = true
  }

  password_policy {
    temporary_password_validity_days = 7
    minimum_length                   = 36
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
  }

  username_configuration {
    case_sensitive = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    name                     = "organization_node_id"
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "Number"
    developer_only_attribute = false
    mutable                  = false
    name                     = "organization_id"
    required                 = false

    number_attribute_constraints {
      min_value = 1
      max_value = 1000000000
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cognito_user_pool_client" "cognito_token_pool_client" {
  name                          = "${var.environment_name}-client-tokens-app-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                  = aws_cognito_user_pool.cognito_token_pool.id
  supported_identity_providers  = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  write_attributes = ["name"]
  read_attributes  = ["custom:organization_id", "custom:organization_node_id"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  lifecycle {
    prevent_destroy = true
  }
}
