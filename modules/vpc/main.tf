# -----------------------------------------------------------------------------
# VPC Module — Network Resources
# Creates the full network foundation: VPC, public/private subnets across
# two AZs, Internet Gateway, NAT Gateway, and route tables with associations.
# -----------------------------------------------------------------------------

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# --- Public Subnets (for ALB) ---
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-${count.index + 1}"
  })
}

# --- Private Subnets (for EC2 and RDS) ---
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-${count.index + 1}"
  })
}

# --- Internet Gateway (public subnets) ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# --- Elastic IP for NAT gateway ---
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eip"
  })
}

# --- NAT Gateway (private subnets use this to reach internet) ---
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-gw"
  })
}

# --- Public Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# --- Private Route Table ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-rt"
  })
}

# --- Associate Public Subnets with Public Route Table ---
resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Associate Private Subnets with Private Route Table ---
resource "aws_route_table_association" "private" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}