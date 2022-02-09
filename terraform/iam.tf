resource "aws_iam_role" "cognito_cloudwatch_logging_role" {
  name = "${var.environment_name}-cognito-cloudwatch-logging-role-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  assume_role_policy = data.aws_iam_policy_document.cognito_cloudwatch_logging_assume_role_policy_document.json
}

data "aws_iam_policy_document" "cognito_cloudwatch_logging_assume_role_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "CognitoAssumeRole"
    effect = "Allow"
    actions = [ "sts:AssumeRole" ]
    principals {
      type        = "Service"
      identifiers = [ "cognito-idp.amazonaws.com" ]
    }
  }
}

resource "aws_iam_policy" "cognito_cloudwatch_logging_policy" {
  name = "${var.environment_name}-cognito-cloudwatch-logging-policy-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  path   = "/"
  policy = data.aws_iam_policy_document.cognito_cloudwatch_logging_policy_document.json
}

data "aws_iam_policy_document" "cognito_cloudwatch_logging_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "CloudWatchLogPermissions"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [ "arn:aws:logs:${var.aws_region}:${var.aws_account}:log-group:/aws/cognito/*" ]
  }
}

resource "aws_iam_role_policy_attachment" "cognito_cloudwatch_logging_role_policy_attachment" {
  role = aws_iam_role.cognito_cloudwatch_logging_role.name
  policy_arn = aws_iam_policy.cognito_cloudwatch_logging_policy.arn
}

