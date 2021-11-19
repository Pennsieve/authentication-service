// POSTGRES CONFIGURATION
resource "aws_ssm_parameter" "authentication_service_postgres_host" {
  name = "/${var.environment_name}/${var.service_name}/postgres-host"
  type = "String"
  value = var.pennsieve_postgres_host
}

resource "aws_ssm_parameter" "authentication_service_postgres_db" {
  name = "/${var.environment_name}/${var.service_name}/postgres-db"
  type = "String"
  value = var.pennsieve_postgres_db
}

resource "aws_ssm_parameter" "authentication_service_postgres_user" {
  name  = "/${var.environment_name}/${var.service_name}/postgres-user"
  type  = "String"
  value = "${var.environment_name}_${replace(var.service_name, "-", "_")}_user"
}

resource "aws_ssm_parameter" "authentication_service_postgres_password" {
  name      = "/${var.environment_name}/${var.service_name}/postgres-password"
  overwrite = false
  type      = "SecureString"
  value     = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}