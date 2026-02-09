# AWS RDS Module

## Description

This module provisions AWS RDS resources, including a DB instance, security group, Secrets Manager secret for password storage, CloudWatch alarms, and SSM parameters for storing instance details.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.3.0 |
| aws       | >= 6.0   |
| external  | >= 2.2.0 |
| random    | >= 3.4.0 |
| time      | >= 0.9   |

## Providers

| Name | Version  |
|------|----------|
| aws  | >= 6.0   |
| external | >= 2.2.0 |
| random | >= 3.4.0 |
| time | >= 0.9 |

## Inputs

| Name                            | Description                                                                      | Type            | Default           | Required |
|---------------------------------|----------------------------------------------------------------------------------|-----------------|-------------------|:--------:|
| project                         | Project name                                                                     | `string`        | -                 |   yes    |
| environment                     | Environment name                                                                 | `string`        | -                 |   yes    |
| name                            | service name                                                                     | `string`        | -                 |   yes    |
| engine                          | Database engine (mysql, postgresql)                                              | `string`        | -                 |   yes    |
| engine_version                  | Database engine version                                                          | `string`        | -                 |   yes    |
| license_model                   | RDS-MSSQL: license-included (Only for MSSQL)                                     | `string`        | -                 |   no     |
| instancetype                    | DB instance type                                                                 | `string`        | "db.t3.micro"     |   no     |
| storage_type                    | DB storage type                                                                  | `string`        | "gp2"             |   no     |
| allocated_storage               | Allocated storage for the DB instance                                            | `number`        | -                 |   yes    |
| max_allocated_storage           | Maximum storage for autoscaling, defining value for this enable autoscaling      | `number`        | -                 |   no     |
| db_name                         | Default database name                                                            | `string`        | -                 |   yes    |
| username                        | Master username for the DB                                                       | `string`        | "opadmin"         |   no     |
| parameter_group_family          | DB parameter group family                                                        | `string`        | -                 |   yes    |
| multi_az                        | Enable multi-AZ deployment                                                       | `bool`          | false             |   no     |
| skip_final_snapshot             | Skip final snapshot before deletion                                              | `bool`          | true              |   no     |
| snapshot_identifier             | Snapshot identifier for restoring the instance                                   | `string`        | ""                |   no     |
| deletion_protection             | Enable deletion protection                                                       | `bool`          | false             |   no     |
| backup_retention_period         | Backup retention period                                                          | `number`        | 30                |   no     |
| storage_encrypted               | Enable encryption for DB storage                                                 | `bool`          | true              |   no     |
| vpc_id                          | VPC ID for the DB instance                                                       | `string`        | -                 |   yes    |
| private_subnet_ids              | List of private subnet IDs                                                       | `list(string)`  | -                 |   yes    |
| vpc_cidr                        | CIDR block of the VPC                                                            | `string`        | -                 |   yes    |
| enable_performance_insights     | Enable performance insights                                                      | `bool`          | -                 |   no     |
| enabled_cloudwatch_logs_exports | Exports log types , refer below link                                             | `list(string)`  | []                |   no     |
| parameter_group_parameters      | Parameters for the DB parameter group                                            | `list(object)`  | []                |   no     |
| kms_key_id                      | KMS key ID for encryption                                                        | `string`        | -                 |   no     |
| alarm_sns_arn                   | SNS topic ARN for alarm notifications                                            | `string`        | ""                |   no     |
| enable_cpu_alarm                | Enable CPU utilization alarms                                                    | `bool`          | false             |   no     |
| port                            | DB Port                                                                          | `number`        | 0                 |   yes    |
| major_engine_version            | Option group major engine version                                                | `string`        | -                 |   yes    |
| option_group_options            | Options for the DB options group                                                 | `list(object)`  | []                |   no     |
| tags                            | tags names                                                                       | `map(string)`   |
-                 |   no     |
## Outputs

| Name              | Description                          |
|-------------------|--------------------------------------|
| db_password_secret| The name of the Secrets Manager secret for the DB password |

## Reference Links

| Name                            | Description                                                                             |
|---------------------------------|---------------------------------------------------------------------------------------  |
| enabled_cloudwatch_logs_exports | https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html     |
| option_group_options - MariaDB  | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.MariaDB.Options.html    |
| option_group_options - MSSQL    | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.Options.html  |
| option_group_options - MySQL    | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.MySQL.Options.html      |
| option_group_options - Oracle   | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.Oracle.Options.html     |



## Usage examples

### Basic Usage Example

```hcl
module "rds" {
  source                      = "https://github.com/opstimus/terraform-aws-rds?ref=v<RELEASE>"
  project                     = "my-project"
  environment                 = "production"
  name                        = "api"
  engine                      = "mysql"
  engine_version              = "5.7.33"
  instancetype                = "db.t3.medium"
  storage_type                = "gp3"
  allocated_storage           = 100
  max_allocated_storage       = 150
  vpc_id                      = "vpc-123456"
  private_subnet_ids          = ["subnet-123456", "subnet-654321"]
  vpc_cidr                    = "10.0.0.0/16"
  db_name                     = "mydb"
  username                    = "admin"
  parameter_group_family      = "mysql5.7"
  multi_az                    = false
  skip_final_snapshot         = true
  deletion_protection         = false
  backup_retention_period     = 7
  storage_encrypted           = true
  enable_performance_insights = false
  enable_cpu_alarm            = true
  alarm_sns_arn               = "arn:aws:sns:us-east-1:123456789012:my-topic"
  port                        = 3306
  major_engine_version        = "16.00"
  option_group_options = [
    {
      option_name = "SQLSERVER_BACKUP_RESTORE"
      option_settings = [
        {
          name  = "IAM_ROLE_ARN"
          value = "role_arn"
        }
      ]
    }
  ]
}
  tags = {
    Name = <project-name>
    Environment = <environment-name>
  }
```

## Notes

The name for the created resource follows the pattern `{project}-{environment}-resource-type`.
