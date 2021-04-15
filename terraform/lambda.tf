resource "aws_lambda_function" "cognito_admin_create_user_email_format" {
  description       = "A description"
  function_name     = "${var.environment_name}-cognito-invite-email-formatter-lambda-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  handler           = "lambda.lambda_handler"
  runtime           = "python3.8"
  role              = aws_iam_role.cognito_invite_email_role.arn
  timeout           = 3
  memory_size       = 128
  source_code_hash  = data.archive_file.lambda_archive.output_base64sha256
  filename          = "${path.module}/lambda.zip"

  environment {
    variables = {
      PENNSIEVE_DOMAIN = data.terraform_remote_state.account.outputs.domain_name
    }
  }
}

resource "aws_lambda_permission" "custom_message_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_admin_create_user_email_format.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.cognito_user_pool.arn
  statement_id  = "AllowInvocationFromCognito"
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "cognito_invite_email_role" {
  name = "${var.environment_name}-${var.service_name}-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

