# AWS RDS Instance

## Description

This Terraform module creates an Amazon RDS database instance, with optional automatic storage scaling, password stored in Secrets Manager, and system parameters stored in Systems Manager Parameter Store.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | ~> 4.0 |
| external | >= 2.2.0 |
| random | >= 3.4.0 |
| time | ~> 0.9 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 4.0 |
| external | >= 2.2.0 |
| random | >= 3.4.0 |
| time | ~> 0.9 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project name | `string` | - | yes |
| environment | Environment name | `string` | - | yes |
| engine | Engine type (mysql, postgresql) | `string` | - | yes |
| engine_version | Engine version (i.e 5.7.33) | `string` | - | yes |
| instancetype | Instance type (micro, medium, or large) | `string` | `db.t3.micro` | no |
| storage_type | Storage type | `string` | `gp2` | no |
| allocated_storage | Storage amount | `number` | - | yes |
| autoscaling | Enable autoscaling | `bool` | `false` | no |
| max_allocated_storage | Autoscale max storage amount | `number` | - | yes (if autoscaling is true) |
| db_name | Default database name | `string` | - | yes |
| username | Master username | `string` | `admin` | no |
| parameter_group_family | Custom parameter group family | `string` | - | yes |
| multi_az | Enable multi AZ | `bool` | `false` | no |
| skip_final_snapshot | Skip final snapshot | `bool` | `true` | no |
| deletion_protection | Enable deletion protection | `bool` | `false` | no |
| backup_retention_period | Backup stored period | `number` | `30` | no |
| storage_encrypted | Enable storage encryption | `bool` | `true` | no |
| vpc_id | VPC ID | `string` | - | yes |
| private_subnet_ids | List of private subnet IDs | `list(string)` | - | yes |
| vpc_cidr | VPC CIDR block | `string` | - | yes |
| enable_performance_insights | Enable Performance Insights | `bool` | - | yes |
| parameter_group_parameters | List of parameters for the parameter group | `list(object({ name = string, value = string }))` | - | yes |
| kms_key_id | KMS key ID to use when storage encryption is true | `string` | - | yes (if storage_encrypted is true) |

## Outputs

| Name | Description |
|------|-------------|
| db_password_secret | The Secrets Manager secret name for the DB password |

## Example Usage

```hcl
module "db_instance" {
  source                    = "s3::https://s3.amazonaws.com/ot-turbo-artifacts/tf/modules/aws/dev/rds.zip"

  project                   = "my_project"
  environment               = "my_environment"
  engine                    = "mysql"
  engine_version            = "5.7.33"
  instancetype              = "db.t3.medium"
  storage_type              = "gp2"
  allocated_storage         = 20
  autoscaling               = true
  max_allocated_storage     = 100
  db_name                   = "my_database"
  username                  = "admin"
  parameter_group_family    = "mysql5.7"
  multi_az                  = false
  skip_final_snapshot       = true
  deletion_protection       = false
  backup_retention_period   = 30
  storage_encrypted         = true
  vpc_id                    = "vpc-abc123"
  private_subnet_ids        = ["subnet-abc123", "subnet-def456"]
  vpc_cidr                  = "10.0.0.0/16"
  enable_performance_insights = true
  parameter_group_parameters = [
    {
      name  = "long_query_time"
      value = "0.5"
    },
    {
      name  = "event_scheduler"
      value = "ON"
    }
  ]
  kms_key_id                = "arn:aws:kms:us-west-2:111122223333:key/abcd1234a1234567890a1234567890a123"
}
```

## Notes

The name for the created resource follows the pattern `{project}-{environment}-resource-type`.
