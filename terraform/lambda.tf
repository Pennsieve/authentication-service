resource "aws_lambda_function" "cognito_custom_email_formatter" {
  description       = "A description"
  function_name     = "${var.environment_name}-cognito-custom-message-email-formatter-lambda-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  handler           = "lambda.lambda_handler"
  runtime           = "python3.8"
  role              = aws_iam_role.cognito_custom_message_email_role.arn
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
  function_name = aws_lambda_function.cognito_custom_email_formatter.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.cognito_user_pool.arn
  statement_id  = "AllowInvocationFromCognito"
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "cognito_custom_message_email_role" {
  name = "${var.environment_name}-${var.service_name}-cognito-custom-email-lambda-role"

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

resource "aws_iam_role_policy_attachment" "cognito_custom_message_lambda_iam_policy_attachment" {
  role       = aws_iam_role.cognito_custom_message_email_role.name
  policy_arn = aws_iam_policy.cognito_custom_message_lambda_iam_policy.arn
}

resource "aws_iam_policy" "cognito_custom_message_lambda_iam_policy" {
  name   = "${var.environment_name}-cognito-custom-message-lambda-iam-policy-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  path   = "/"
  policy = data.aws_iam_policy_document.cognito_custom_message_lambda_iam_policy_document.json
}

data "aws_iam_policy_document" "cognito_custom_message_lambda_iam_policy_document" {
  statement {
    sid    = "CloudwatchLogPermissions"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutDestination",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

