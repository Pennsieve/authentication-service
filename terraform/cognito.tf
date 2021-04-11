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

  email_verification_message = templatefile("${path.module}/emails/password-reset.template.html", { PENNSIEVE_DOMAIN = data.terraform_remote_state.account.outputs.domain_name })

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true

    invite_message_template {
      email_message = templatefile("${path.module}/emails/new-account-creation.template.html", { PENNSIEVE_DOMAIN = data.terraform_remote_state.account.outputs.domain_name })
      email_subject = "Welcome to Pennsieve - setup your account"
      sms_message   = "Please visit https://app.${data.terraform_remote_state.account.outputs.domain_name}/invitation/accept?email={username}&tempPassword={####}"
    }
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

resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  name                          = "${var.environment_name}-users-app-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                  = aws_cognito_user_pool.cognito_user_pool.id
  supported_identity_providers  = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows           = ["USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

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
    temporary_password_validity_days = 0
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
    developer_only_attribute = true
    mutable                  = false
    name                     = "organization_node_id"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "Number"
    developer_only_attribute = true
    mutable                  = false
    name                     = "organization_id"
    required                 = true

    number_attribute_constraints {
      min_value = 1
      max_value = 1000000000
    }
  }
}

resource "aws_cognito_user_pool_client" "cognito_token_pool_client" {
  name                          = "${var.environment_name}-client-tokens-app-client-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  user_pool_id                  = aws_cognito_user_pool.cognito_token_pool.id
  supported_identity_providers  = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows           = ["USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

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
}
