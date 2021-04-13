resource "aws_lambda_function" "cognito_admin_create_user_email_format" {
  description       = "A description"
  function_name     = "${var.environment_name}_cognito_invite_email_formatter_lambda_${data.terraform_remote_state.region}"
  handler           = "lambda.handler"
  runtime           = "python3.8"
  role              = aws_iam_role.cognito_invite_email_role.arn
  timeout           = 3
  memory_size       = 128
  source_code_hash  = data.archive_file.lambda_archive.output_base64sha256
  filename          = "${path.module}/lambda/lambda.zip"
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda.py"

  source {
    content  = data.template_file.lambda_function.rendered
    filename = "new-account-creation.template.html"
  }

  output_path = "${path.module}/lambda/lambda.zip"
}

data "template_file" "lambda_function" {
  template = "emails/new-account-creation.template.html"
  vars = {
    PENNSIEVE_DOMAIN = data.terraform_remote_state.account.outputs.domain_name
  }
}

resource "aws_iam_role" "cognito_invite_email_role" {
  name = "cognito_invite_email_role"

  # modeled the policy based on 
  # https://github.com/Pennsieve/infrastructure/blob/662fc6dba48a8dcfdf06dd46ac7e961164fdc869/aws/aws-sparc/iam.tf#L28
  # https://awspolicygen.s3.amazonaws.com/policygen.html

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeAsync",
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:lambda:us-east-1:${var.external_aws_account_id}:root"
    }
  ]
}
EOF

}
