output "db_password_secret" {
  value = aws_secretsmanager_secret.main.name
}

resource "aws_ssm_parameter" "dns" {
  name  = "/${var.project}/${var.environment}${local.ssm_name}/central/rds/dns"
  type  = "String"
  value = aws_db_instance.main.address
}

resource "aws_ssm_parameter" "username" {
  name  = "/${var.project}/${var.environment}${local.ssm_name}/central/rds/username"
  type  = "String"
  value = var.username
}

resource "aws_ssm_parameter" "db_name" {
  count = var.db_name != "" ? 1 : 0
  name  = "/${var.project}/${var.environment}${local.ssm_name}/central/rds/db_name"
  type  = "String"
  value = var.db_name
}
