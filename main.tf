locals {
  name     = var.name != "" ? "-${var.name}" : ""
  ssm_name = var.name != "" ? "/${var.name}" : ""
}

resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}${local.name}-db"
  description = "${var.project}-${var.environment}${local.name}-db"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "random_password" "main" {
  length           = 16
  special          = true
  override_special = "!#$%&*?"
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.project}-${var.environment}${local.name}-db"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = random_password.main.result
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}${local.name}"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_db_parameter_group" "main" {
  count  = length(var.parameter_group_parameters) != 0 ? 1 : 0
  name   = "${var.project}-${var.environment}-${var.engine}${local.name}"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameter_group_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

resource "aws_db_option_group" "main" {
  name                     = "${var.project}-${var.environment}-${var.engine}${local.name}"
  option_group_description = "${var.project}-${var.environment}-${var.engine}${local.name}"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version
  dynamic "option" {
    for_each = var.option_group_options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = option.value.option_settings
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }

      }
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

resource "time_static" "main" {}

resource "aws_db_instance" "main" {
  apply_immediately               = true
  engine                          = var.engine
  engine_version                  = var.engine_version
  license_model                   = var.license_model
  parameter_group_name            = length(aws_db_parameter_group.main) > 0 ? aws_db_parameter_group.main[0].name : "default.${var.parameter_group_family}"
  option_group_name               = aws_db_option_group.main.name
  auto_minor_version_upgrade      = false
  db_subnet_group_name            = aws_db_subnet_group.main.name
  instance_class                  = var.instancetype
  storage_type                    = var.storage_type
  allocated_storage               = var.allocated_storage
  max_allocated_storage           = var.max_allocated_storage
  db_name                         = var.db_name
  username                        = var.username
  password                        = random_password.main.result
  multi_az                        = var.multi_az
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "${var.project}-${var.environment}-${time_static.main.unix}"
  snapshot_identifier             = var.snapshot_identifier != "" ? var.snapshot_identifier : null
  deletion_protection             = var.deletion_protection
  backup_retention_period         = var.backup_retention_period
  identifier                      = "${var.project}-${var.environment}${local.name}"
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.storage_encrypted == true ? var.kms_key_id : null
  vpc_security_group_ids          = [aws_security_group.db.id]
  performance_insights_enabled    = var.enable_performance_insights
  tags                            = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count                     = var.enable_cpu_alarm ? 1 : 0
  alarm_name                = "${var.project}-${var.environment}${local.name}: CPU usage on RDS '${aws_db_instance.main.id}' is high"
  alarm_description         = "RDS CPU utlization high"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 15
  datapoints_to_alarm       = 10
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 70
  insufficient_data_actions = []
  alarm_actions             = [var.alarm_sns_arn]
  ok_actions                = [var.alarm_sns_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_critical" {
  count                     = var.enable_cpu_alarm ? 1 : 0
  alarm_name                = "${var.project}-${var.environment}${local.name}: CPU usage on RDS '${aws_db_instance.main.id}' is critical"
  alarm_description         = "RDS CPU utlization critical"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 15
  datapoints_to_alarm       = 10
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 70
  insufficient_data_actions = []
  alarm_actions             = [var.alarm_sns_arn]
  ok_actions                = [var.alarm_sns_arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  tags = var.tags
}
