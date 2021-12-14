resource "aws_lambda_layer_version" "lambda_python_psycopg2_layer" {
  layer_name = "${var.environment_name}-lambda-python-psycopg2-layer-${data.terraform_remote_state.region.outputs.aws_region_shortname}"
  filename = data.archive_file.lambda_python_psycopg2_layer_archive.output_path
  
  compatible_runtimes = ["python3.8"]
  compatible_architectures = ["x86_64"]
}

data "archive_file" "lambda_python_psycopg2_layer_archive" {
  type        = "zip"
  source_dir  = "${path.module}/layers/psycopg2"
  output_path = "${path.module}/lambda-python-psycopg2-layer.zip"
}
