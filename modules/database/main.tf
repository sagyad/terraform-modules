
# -----------------------------------------------------------------------------
# Database Module — Resources
# Creates RDS Security Group, DB Subnet Group, and RDS Multi-AZ Instance.
# RDS is placed in private subnets — only EC2 instances can connect.
# -----------------------------------------------------------------------------

# --- RDS Security Group ---
# Only allows PostgreSQL traffic (5432) from EC2 security group
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow PostgreSQL inbound from EC2 only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EC2 only"
    from_port       = 5432
    to_port         = 5432
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
    Name = "${var.name_prefix}-rds-sg"
  })
}

# --- DB Subnet Group ---
# Bundles private subnets so RDS knows where to place Primary and Standby
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet"
  })
}

# --- RDS PostgreSQL Multi-AZ Instance ---
# Primary in AZ-a, synchronous standby in AZ-b (automatic failover)
resource "aws_db_instance" "main" {
  identifier     = "${var.name_prefix}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Multi-AZ — the whole point of this project!
  multi_az = true

  # Network — private subnets, protected by SG
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Dev settings — skip snapshot on destroy to save time and cost
  skip_final_snapshot = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db"
  })
}

