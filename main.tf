resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-db"
  description = "${var.project}-${var.environment}-db"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.from_port
    to_port     = var.to_port
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

  tags = {
    Name = "${var.project}-${var.environment}-db"
  }
}

resource "random_password" "main" {
  length           = 16
  special          = true
  override_special = "!#$%&*?"
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.project}-${var.environment}-db"
}
resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = random_password.main.result
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

resource "aws_db_parameter_group" "main" {
  count  = length(var.parameter_group_parameters) != 0 ? 1 : 0
  name   = "${var.project}-${var.environment}-${var.engine}"
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
}

resource "time_static" "main" {}

resource "aws_db_instance" "main" {
  apply_immediately            = true
  engine                       = var.engine
  engine_version               = var.engine_version
  parameter_group_name         = length(aws_db_parameter_group.main) > 0 ? aws_db_parameter_group.main[0].name : "default.${var.parameter_group_family}"
  auto_minor_version_upgrade   = false
  db_subnet_group_name         = aws_db_subnet_group.main.name
  instance_class               = var.instancetype
  storage_type                 = var.storage_type
  allocated_storage            = var.allocated_storage
  max_allocated_storage        = var.autoscaling == true ? var.max_allocated_storage : null
  db_name                      = var.db_name
  username                     = var.username
  password                     = random_password.main.result
  multi_az                     = var.multi_az
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = "${var.project}-${var.environment}-${time_static.main.unix}"
  snapshot_identifier          = var.snapshot_identifier != "" ? var.snapshot_identifier : null
  deletion_protection          = var.deletion_protection
  backup_retention_period      = var.backup_retention_period
  identifier                   = "${var.project}-${var.environment}"
  storage_encrypted            = var.storage_encrypted
  kms_key_id                   = var.storage_encrypted == true ? var.kms_key_id : null
  vpc_security_group_ids       = [aws_security_group.db.id]
  performance_insights_enabled = var.enable_performance_insights
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count                     = var.enable_cpu_alarm ? 1 : 0
  alarm_name                = "${var.project}-${var.environment}: CPU usage on RDS '${aws_db_instance.main.id}' is high"
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
}

resource "aws_cloudwatch_metric_alarm" "cpu_critical" {
  count                     = var.enable_cpu_alarm ? 1 : 0
  alarm_name                = "${var.project}-${var.environment}: CPU usage on RDS '${aws_db_instance.main.id}' is critical"
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
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-${var.environment}-rds-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project}-${var.environment}-rds-scheduler-policy"
  description = "Allow Lambda to manage RDS"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:StopDBInstance",
          "rds:StartDBInstance"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "local_file" "rds_scheduler_script" {
  content  = <<EOT
import boto3
import os

def rds_scheduler(event, context):
    action = event.get('action', None)
    db_instance = os.environ.get('DB_INSTANCE')
    rds = boto3.client('rds')

    if action == "stop":
        response = rds.stop_db_instance(DBInstanceIdentifier=db_instance)
        return {"status": "stopped", "response": response}

    elif action == "start":
        response = rds.start_db_instance(DBInstanceIdentifier=db_instance)
        return {"status": "started", "response": response}

    return {"status": "unknown action"}
EOT
  filename = "${path.module}/rds_scheduler.py"
}

data "archive_file" "rds_scheduler_zip" {
  type        = "zip"
  source_file = local_file.rds_scheduler_script.filename # Correctly reference the local file here
  output_path = "${path.module}/rds_scheduler.zip"
}

resource "aws_lambda_function" "rds_scheduler" {
  count         = var.enable_scheduled_shutdown ? 1 : 0
  function_name = "${var.project}-${var.environment}-rds-scheduler"
  runtime       = "python3.9"
  handler       = "rds_scheduler.rds_scheduler"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.rds_scheduler_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.rds_scheduler_zip.output_path)

  environment {
    variables = {
      DB_INSTANCE = aws_db_instance.main.id
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-rds-scheduler"
  }
}


resource "aws_cloudwatch_event_rule" "scheduled_shutdown" {
  count               = var.enable_scheduled_shutdown ? 1 : 0
  name                = "${var.project}-${var.environment}-shutdown-rule"
  schedule_expression = var.scheduled_shutdown_at
}

resource "aws_cloudwatch_event_rule" "scheduled_wakeup" {
  count               = var.enable_scheduled_shutdown ? 1 : 0
  name                = "${var.project}-${var.environment}-wakeup-rule"
  schedule_expression = var.scheduled_wakeup_at
}

resource "aws_cloudwatch_event_target" "shutdown_target" {
  count     = var.enable_scheduled_shutdown ? 1 : 0
  rule      = aws_cloudwatch_event_rule.shutdown.name
  target_id = "shutdown"
  arn       = aws_lambda_function.rds_scheduler.arn
  input     = jsonencode({ action = "stop" })
}

resource "aws_cloudwatch_event_target" "wakeup_target" {
  count     = var.enable_scheduled_shutdown ? 1 : 0
  rule      = aws_cloudwatch_event_rule.wakeup.name
  target_id = "wakeup"
  arn       = aws_lambda_function.rds_scheduler.arn
  input     = jsonencode({ action = "start" })
}

resource "aws_lambda_permission" "event_permission" {
  count         = var.enable_scheduled_shutdown ? 2 : 0
  statement_id  = "AllowExecutionFromEventBridge-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_scheduler.arn
  principal     = "events.amazonaws.com"
  source_arn    = count.index == 0 ? aws_cloudwatch_event_rule.scheduled_shutdown[0].arn : aws_cloudwatch_event_rule.scheduled_wakeup[0].arn
}


