# Terraform Configuration with IaC Security Vulnerabilities
# This file contains intentional security misconfigurations for testing

terraform {
  required_version = ">= 0.12"
  
  # Vulnerability 1: No backend encryption configured
  backend "s3" {
    bucket = "terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
  
  # Vulnerability 2: Hardcoded credentials
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# Vulnerability 3: S3 bucket with public access
resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-public-bucket-12345"
}

resource "aws_s3_bucket_acl" "public_bucket_acl" {
  bucket = aws_s3_bucket.public_bucket.id
  acl    = "public-read"  # Everyone can read
}

resource "aws_s3_bucket_public_access_block" "public_bucket_pab" {
  bucket = aws_s3_bucket.public_bucket.id
  
  # Vulnerability 7: Public access enabled
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Vulnerability 8: Security group with unrestricted access
resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Vulnerability 9: EC2 instance with insecure configuration
resource "aws_instance" "vulnerable_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  monitoring = false
  
  # Vulnerability 14: User data with secrets
  user_data = <<-EOF
              #!/bin/bash
              export DATABASE_PASSWORD="SuperSecretPassword123"
              export API_KEY="sk-1234567890abcdef"
              echo "root:password" | chpasswd
              EOF
  
  tags = {
    Name = "Vulnerable Instance"
  }
}

# Vulnerability 16: RDS database with weak settings
resource "aws_db_instance" "vulnerable_db" {
  identifier = "vulnerable-database"
  
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  
  # Vulnerability 17: Weak credentials
  username = "admin"
  password = "password123"
  
  publicly_accessible = true
  storage_encrypted = false
  backup_retention_period = 0
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  multi_az = false
  deletion_protection = false
}

# Vulnerability 26: IAM user with hardcoded credentials
resource "aws_iam_user" "vulnerable_user" {
  name = "vulnerable-user"
}

resource "aws_iam_access_key" "vulnerable_key" {
  user = aws_iam_user.vulnerable_user.name
}

# Vulnerability 27: Overly permissive IAM policy
resource "aws_iam_policy" "admin_policy" {
  name = "admin-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "vulnerable_attach" {
  user       = aws_iam_user.vulnerable_user.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

# Output sensitive information
output "database_password" {
  value = aws_db_instance.vulnerable_db.password
}

output "access_key" {
  value = aws_iam_access_key.vulnerable_key.id
}

output "secret_key" {
  value = aws_iam_access_key.vulnerable_key.secret
}
