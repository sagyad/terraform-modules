# -----------------------------------------------------------------------------
# Compute Module — Input Variables
# Only values the module needs FROM OUTSIDE to build the compute layer.
# Resources like ALB, EC2, ASG are created inside main.tf.
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public Subnet"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private Subnet"
  type        = list(string)
}

variable "name_prefix" {
  description = "Naming prefix for all resources (e.g. ha-multi-az-dev)"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t3.micro)"
  type        = string
}
variable "min_capacity" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
}