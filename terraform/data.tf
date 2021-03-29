# Import Region Data
data "terraform_remote_state" "region" {
  backend = "s3"

  config = {
    bucket = "${var.aws_account}-terraform-state"
    key    = "aws/${var.aws_region}/terraform.tfstate"
    region = "us-east-1"
  }
}
