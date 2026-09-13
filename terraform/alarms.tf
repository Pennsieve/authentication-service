# T1 CloudWatch alarms (EPIC 868m2zvjt; standard sets from
# pennsieve-infra-dashboard/docs/alarm-coverage-plan.md). These are Cognito
# user-pool triggers: an error in pre-sign-up or post-authentication is a
# failed login or sign-up for a user. No alarm_actions yet: alarms surface
# on the infra dashboard and console without paging.
module "service_alarms" {
  source = "git@github.com:Pennsieve/terraform-modules.git//service-alarms"

  environment_name = var.environment_name
  service_name     = var.service_name

  lambdas = {
    pre-sign-up = {
      function_name   = aws_lambda_function.cognito_pre_sign_up_lambda.function_name
      timeout_seconds = aws_lambda_function.cognito_pre_sign_up_lambda.timeout
    }
    post-authentication = {
      function_name   = aws_lambda_function.cognito_post_authentication_lambda.function_name
      timeout_seconds = aws_lambda_function.cognito_post_authentication_lambda.timeout
    }
    custom-message = {
      function_name   = aws_lambda_function.cognito_custom_message_lambda.function_name
      timeout_seconds = aws_lambda_function.cognito_custom_message_lambda.timeout
    }
    users2-migration = {
      function_name   = aws_lambda_function.cognito_users2_migration_lambda.function_name
      timeout_seconds = aws_lambda_function.cognito_users2_migration_lambda.timeout
    }
  }
}
