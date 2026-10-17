// #### cognito_custom_message_lambda ####
resource "aws_cloudwatch_log_group" "custom_message_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_custom_message_lambda.function_name}"
  retention_in_days = 30
  tags              = local.common_tags
}

// #### cognito_post_authentication_lambda ####
resource "aws_cloudwatch_log_group" "post_auth_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_post_authentication_lambda.function_name}"
  retention_in_days = 30
  tags              = local.common_tags
}

// #### cognito_pre_sign_up_lambda ####
resource "aws_cloudwatch_log_group" "pre_signup_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_pre_sign_up_lambda.function_name}"
  retention_in_days = 30
  tags              = local.common_tags
}

// #### cognito_users2_migration_lambda ####
resource "aws_cloudwatch_log_group" "migration_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_users2_migration_lambda.function_name}"
  retention_in_days = 30
  tags              = local.common_tags
}
