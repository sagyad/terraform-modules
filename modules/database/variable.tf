# -----------------------------------------------------------------------------
# Database Module — Input Variables
# Only values the module needs FROM OUTSIDE to build the database layer.
# Resources like RDS, subnet group, SG are created inside main.tf
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID for security group creation"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS Multi-AZ placement"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "EC2 Security Group ID — only EC2 can talk to RDS"
  type        = string
}

variable "name_prefix" {
  description = "Project Name for resource tagging"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}

variable "db_instance_class" {
  description = "RDS instance class (e.g. db.t3.micro)"
  type        = string
}

variable "db_name" {
  description = "Database Name"
  type        = string
}

variable "db_username" {
  description = "Database UserName"
  type        = string
}

variable "db_password" {
  description = "Master password for RDS (passed via TF_VAR — never in tfvars)"
  type        = string
  sensitive   = true
}