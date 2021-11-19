resource "aws_lambda_function" "cognito_post_authentication_lambda" {
  description      = "Executes post authentication to verify the cognito_id is corrrect in the Pennsieve USERS table for the logged in user."
  function_name    = "${var.environment_name}-${var.service_name}-post-authentication-lambda-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  handler          = "lambda.handler"
  runtime          = "python3.8"
  role             = aws_iam_role.cognito_post_authentication_lambda_role.arn
  timeout          = 3
  memory_size      = 128
  source_code_hash = data.archive_file.cognito_post_authentication_lambda_archive.output_base64sha256
  filename         = "${path.module}/post-auth.zip"
  
  environment {
    variables = {
      PENNSIEVE_ENV = var.environment_name
    }
  }
  
  vpc_config {
    subnet_ids         = tolist(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
    security_group_ids = [data.terraform_remote_state.platform_infrastructure.outputs.authentication_service_security_group_id]
  }
}

resource "aws_iam_role" "cognito_post_authentication_lambda_role" {
  name = "${var.environment_name}-${var.service_name}-post-authentication-lambda-role-${data.terraform_remote_state.region.outputs.aws_region_shortname}"

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

data "archive_file" "cognito_post_authentication_lambda_archive" {
  type        = "zip"
  source_dir  = "${path.module}/post-auth"
  output_path = "${path.module}/post-auth.zip"
}

resource "aws_lambda_permission" "post_authentication_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_post_authentication_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.cognito_user_pool_2.arn
  statement_id  = "AllowInvocationFromCognito"
}

resource "aws_iam_policy" "cognito_post_authentication_lambda_iam_policy" {
  name   = "${var.environment_name}-${var.service_name}-post-authentication-lambda-iam-policy-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  path   = "/"
  policy = data.aws_iam_policy_document.cognito_post_authentication_lambda_iam_policy_document.json
}

data "aws_iam_policy_document" "cognito_post_authentication_lambda_iam_policy_document" {
  statement {
    sid    = "CloudwatchLogPermissions"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutDestination",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
  
  statement {
    sid    = "EC2NetworkPermissions"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
  
  statement {
    sid    = "SSMPermissions"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment_name}/${var.service_name}/*"]
  }
}

resource "aws_iam_role_policy_attachment" "cognito_post_authentication_lambda_iam_policy_attachment" {
  role       = aws_iam_role.cognito_post_authentication_lambda_role.name
  policy_arn = aws_iam_policy.cognito_post_authentication_lambda_iam_policy.arn
}
