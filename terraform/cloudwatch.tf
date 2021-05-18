resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_log_group_subscription" {
  name            = "/aws/lambda/${aws_lambda_function.cognito_custom_message_lambda.function_name}-subscription"
  log_group_name  = "/aws/lambda/${aws_lambda_function.cognito_custom_message_lambda.function_name}"
  filter_pattern  = ""
  destination_arn = data.terraform_remote_state.region.outputs.datadog_delivery_stream_arn
  role_arn        = data.terraform_remote_state.region.outputs.cw_logs_to_datadog_logs_firehose_role_arn
}