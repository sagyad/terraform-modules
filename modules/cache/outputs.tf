# -----------------------------------------------------------------------------
# Redis Module — Outputs
# Exposes Redis endpoint for application configuration.
# -----------------------------------------------------------------------------

output "redis_endpoint" {
  description = "Rediscache endpoint - app use this to connect to Redis"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}