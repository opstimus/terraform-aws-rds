variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "name" {
  type        = string
  description = "Service name"
  default     = ""
}

variable "engine" {
  type        = string
  description = "mysql, postgresql"
}

variable "engine_version" {
  type        = string
  description = "i.e 5.7.33"
}

variable "license_model" {
  type        = string
  default     = null
  description = "RDS-MariaDB & RDS-MySQL: general-public-license | RDS-MSSQL: license-included | RDS Oracle: bring-your-own-license, license-included | RDS PostgreSQL: postgresql-license"
}

variable "instancetype" {
  type        = string
  description = "Instance type (micro, medium or large)"
  default     = "db.t3.micro"
}

variable "storage_type" {
  type    = string
  default = "gp2"
}

variable "allocated_storage" {
  type        = number
  description = "Storage amount"
}

variable "autoscaling" {
  type    = bool
  default = false
}

variable "max_allocated_storage" {
  type        = number
  description = "Autoscale max storage amount"
}

variable "db_name" {
  type        = string
  description = "Default database name"
  default     = ""
}

variable "username" {
  type        = string
  description = "Master username"
  default     = "opadmin"
}

variable "parameter_group_family" {
  type = string
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "snapshot_identifier" {
  type    = string
  default = ""
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type        = number
  description = "Backup stored period"
  default     = 30
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "enable_performance_insights" {
  type = bool
}

variable "parameter_group_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "kms_key_id" {
  type        = string
  description = "KMS key id to use when storage encryption is true"
}

variable "alarm_sns_arn" {
  type        = string
  description = "SNS topic arn"
  default     = ""
}

variable "enable_cpu_alarm" {
  type        = bool
  description = "Enable CPU alarm"
  default     = false
}

variable "from_port" {
  type = number
}

variable "to_port" {
  type = number
}
