resource "aws_lambda_function" "cognito_users2_migration_lambda" {
  description      = "Migrate Cognito users to users2 user pool."
  function_name    = "${var.environment_name}-${var.service_name}-users2-migration-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  role             = aws_iam_role.cognito_users2_migration_lambda_role.arn
  timeout          = 3
  memory_size      = 128
  source_code_hash = data.archive_file.users2_migration_lambda_archive.output_base64sha256
  filename         = data.archive_file.users2_migration_lambda_archive.output_path

  environment {
    variables = {
      OLD_CLIENT_ID = aws_cognito_user_pool_client.cognito_user_pool_admin_client.id
      OLD_USER_POOL_ID = aws_cognito_user_pool.cognito_user_pool.id
      OLD_USER_POOL_REGION = "us-east-1"
    }
  }
}

resource "aws_lambda_permission" "cognito_users2_migration_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_users2_migration_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.cognito_user_pool_2.arn
  statement_id  = "AllowInvocationFromCognito"
}

data "archive_file" "users2_migration_lambda_archive" {
  type        = "zip"
  source_dir  = "${path.module}/migration"
  output_path = "${path.module}/migration.zip"
}

resource "aws_iam_role" "cognito_users2_migration_lambda_role" {
  name = "${var.environment_name}-${var.service_name}-users2-migration-role-${data.terraform_remote_state.region.outputs.aws_region_shortname}"

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

  inline_policy {
    name = "cognito_users2_migration_inline_policy"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "cognito-idp:AdminInitiateAuth",
                    "cognito-idp:AdminGetUser"
                ],
                "Resource": aws_cognito_user_pool.cognito_user_pool.arn
            }
        ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "cognito_users2_migration_lambda_iam_policy_attachment" {
  role       = aws_iam_role.cognito_users2_migration_lambda_role.name
  policy_arn = aws_iam_policy.cognito_users2_migration_lambda_iam_policy.arn
}

resource "aws_iam_policy" "cognito_users2_migration_lambda_iam_policy" {
  name   = "${var.environment_name}-${var.service_name}-custom-message-lambda-iam-policy-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  path   = "/"
  policy = data.aws_iam_policy_document.cognito_users2_migration_lambda_iam_policy_document.json
}

data "aws_iam_policy_document" "cognito_users2_migration_lambda_iam_policy_document" {
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
