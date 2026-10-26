# -----------------------------------------------------------------------------
# Database Module — Resources
# Exposes compute values for use by database, cache, and root modules.
# -----------------------------------------------------------------------------

output "ec2_security_group" {
  description = "EC2 Security Group ID — used by RDS and Redis to allow inbound"
  value       = aws_security_group.ec2.id
}

output "alb_dns_name" {
  description = "ALB DNS name — the URL to access the application"
  value       = aws_lb.main.dns_name
}