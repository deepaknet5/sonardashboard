provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Data source for the specific VPC
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Data source for subnets in that VPC
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "sonar-dashboard-rds-sg"
  description = "Allow inbound traffic to Postgres"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: In production, restrict to specific IPs or Security Groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "sonar-dashboard-db-subnet-group"
  subnet_ids = data.aws_subnets.selected.ids

  tags = {
    Name = "SonarDashboardDBSubnetGroup"
  }
}

# RDS Instance
resource "aws_db_instance" "default" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "16.6" 
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres16"
  skip_final_snapshot    = true
  publicly_accessible    = true 
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  
  tags = {
    Name = "SonarDashboardDB"
  }
}
