# -----------------------------------------------------------------------------
# Cache Module — Input Variables
# Only values the module needs FROM OUTSIDE to build the caching layer.
# Resources like ElastiCache, subnet group, SG are created inside main.tf.
# -----------------------------------------------------------------------------


variable "vpc_id" {
  description = "VPC ID for security group creation"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ElastiCache Redis placement"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "EC2 Security Group ID — only EC2 can talk to Redis"
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

variable "redis_node_type" {
  description = "Rediscache instance class (e.g. db.t3.micro)"
  type        = string
}
