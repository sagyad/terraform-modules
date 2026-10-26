
# -----------------------------------------------------------------------------
# Compute Module — Resources
# Creates ALB, Auto Scaling Group, Launch Template, and Security Groups.
# ALB sits in public subnets, EC2 instances in private subnets.
# -----------------------------------------------------------------------------

# --- Data Source: Latest Amazon Linux AMI ---
# AMI IDs — this always gets the latest Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- ALB Security Group ---
# Allows HTTP traffic from the internet to the load balancer
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

# --- EC2 Security Group ---
# Only allows traffic FROM the ALB — not directly from the internet
# This is called "security group chaining"
resource "aws_security_group" "ec2" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "Allow HTTP inbound from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ec2-sg"
  })
}

# --- Application Load Balancer ---
# Public-facing, distributes traffic across EC2 in both AZs
resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb"
  })
}

# --- ALB Target Group ---
# ALB sends traffic here — health check ensures only healthy EC2s get traffic
resource "aws_lb_target_group" "main" {
  name     = "${var.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-tg"
  })
}

# --- ALB Listener ---
# Listens on port 80 and forwards to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# --- Launch Template ---
# Defines what each EC2 instance looks like when ASG creates it
resource "aws_launch_template" "main" {
  name          = "${var.name_prefix}-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Simple web server — in real job, developer provides the AMI
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "<h1>HA Multi-AZ | $(hostname)</h1>" > /var/www/html/index.html
    echo "OK" > /var/www/html/health
    systemctl start httpd
    systemctl enable httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.name_prefix}-ec2"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-lt"
  })
}

# --- Auto Scaling Group ---
# Maintains desired number of EC2 instances across AZs
# If one dies, ASG automatically replaces it
resource "aws_autoscaling_group" "main" {
  name                = "${var.name_prefix}-asg"
  min_size            = var.min_capacity
  max_size            = var.max_capacity
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ec2"
    propagate_at_launch = true
  }
}

