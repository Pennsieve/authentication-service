resource "aws_lambda_function" "cognito_admin_create_user_email_format" {
  description       = "A description"
  function_name     = "${var.environment_name}_cognito_invite_email_formatter_lambda_${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  handler           = "lambda.handler"
  runtime           = "python3.8"
  role              = aws_iam_role.cognito_invite_email_role.arn
  timeout           = 3
  memory_size       = 128
  source_code_hash  = data.archive_file.lambda_archive.output_base64sha256
  filename          = "${path.module}/lambda/lambda.zip"

  environment {
    variables = {
      PENNSIEVE_DOMAIN = data.terraform_remote_state.account.outputs.domain_name
    }
  }
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/lambda.zip"
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
