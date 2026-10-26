# -----------------------------------------------------------------------------
# VPC Module — Outputs
# Exposes VPC and subnet IDs for use by compute, database, and cache modules.
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnets IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnets IDs"
  value       = aws_subnet.private[*].id
}