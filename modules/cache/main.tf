# -----------------------------------------------------------------------------
# Rediscache Module — Resources
# Creates Redis Cache Security Group, Redis Subnet Group, and Redis Multi-AZ Instance.
# Rediscache is placed in private subnets — only EC2 instances can connect.
# -----------------------------------------------------------------------------

# --- Redis Security Group ---
# Only allows Redis traffic (6379) from EC2 security group
resource "aws_security_group" "redis" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Allow Redis inbound from EC2 only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EC2 only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-redis-sg"
  })
}

# --- Redis Subnet Group ---
# Bundles private subnets so Redis knows where to place Primary and Standby
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-redis-subnet"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-redis-subnet"
  })
}

# --- Redis Multi-AZ Instance ---
# Primary in AZ-a, synchronous standby in AZ-b (automatic failover)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "Redis Multi-AZ with automatic failover"
  node_type            = var.redis_node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  # Simple Multi-AZ: 1 Primary + 1 Replica = 2 cache clusters
  num_cache_clusters         = 2
  automatic_failover_enabled = true

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-redis"
  })
}