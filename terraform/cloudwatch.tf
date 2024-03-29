// #### cognito_custom_message_lambda ####
resource "aws_cloudwatch_log_group" "custom_message_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_custom_message_lambda.function_name}"
  retention_in_days = 30
  tags = local.common_tags
}
resource "aws_cloudwatch_log_subscription_filter" "custom_message_cloudwatch_log_group_subscription" {
  name            = "${aws_cloudwatch_log_group.custom_message_lambda_loggroup.name}-subscription"
  log_group_name  = aws_cloudwatch_log_group.custom_message_lambda_loggroup.name
  filter_pattern  = ""
  destination_arn = data.terraform_remote_state.region.outputs.datadog_delivery_stream_arn
  role_arn        = data.terraform_remote_state.region.outputs.cw_logs_to_datadog_logs_firehose_role_arn
}


// #### cognito_post_authentication_lambda ####
resource "aws_cloudwatch_log_group" "post_auth_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_post_authentication_lambda.function_name}"
  retention_in_days = 30
  tags = local.common_tags
}

resource "aws_cloudwatch_log_subscription_filter" "post_auth_log_group_subscription" {
  name            = "${aws_cloudwatch_log_group.post_auth_lambda_loggroup.name}-subscription"
  log_group_name  = aws_cloudwatch_log_group.post_auth_lambda_loggroup.name
  filter_pattern  = ""
  destination_arn = data.terraform_remote_state.region.outputs.datadog_delivery_stream_arn
  role_arn        = data.terraform_remote_state.region.outputs.cw_logs_to_datadog_logs_firehose_role_arn
}

// #### cognito_pre_sign_up_lambda ####
resource "aws_cloudwatch_log_group" "pre_signup_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_pre_sign_up_lambda.function_name}"
  retention_in_days = 30
  tags = local.common_tags
}

resource "aws_cloudwatch_log_subscription_filter" "pre_signup_log_group_subscription" {
  name            = "${aws_cloudwatch_log_group.pre_signup_lambda_loggroup.name}-subscription"
  log_group_name  = aws_cloudwatch_log_group.pre_signup_lambda_loggroup.name
  filter_pattern  = ""
  destination_arn = data.terraform_remote_state.region.outputs.datadog_delivery_stream_arn
  role_arn        = data.terraform_remote_state.region.outputs.cw_logs_to_datadog_logs_firehose_role_arn
}

// #### cognito_users2_migration_lambda ####
resource "aws_cloudwatch_log_group" "migration_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_users2_migration_lambda.function_name}"
  retention_in_days = 30
  tags = local.common_tags
}

resource "aws_cloudwatch_log_subscription_filter" "migration_log_group_subscription" {
  name            = "${aws_cloudwatch_log_group.migration_lambda_loggroup.name}-subscription"
  log_group_name  = aws_cloudwatch_log_group.migration_lambda_loggroup.name
  filter_pattern  = ""
  destination_arn = data.terraform_remote_state.region.outputs.datadog_delivery_stream_arn
  role_arn        = data.terraform_remote_state.region.outputs.cw_logs_to_datadog_logs_firehose_role_arn
}