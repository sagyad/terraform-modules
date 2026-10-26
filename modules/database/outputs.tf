# -----------------------------------------------------------------------------
# Database Module — Outputs
# Exposes RDS endpoint for application configuration.
# -----------------------------------------------------------------------------

output "db_endpoint" {
  description = "RDS endpoint - apps use this to connect to the database"
  value       = aws_db_instance.main.endpoint
}