# -----------------------------------------------------------------------------
# VPC Module — Input Variables
# Only values the module needs FROM OUTSIDE to build the network.
# Resources like IGW, NAT, route tables are created inside main.tf.
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Naming prefix for all resources (e.g. ha-multi-az-dev)"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)"
  type        = string
}

variable "azs" {
  description = "Availability Zones for Multi-AZ deployment"
  type        = list(string)
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}


