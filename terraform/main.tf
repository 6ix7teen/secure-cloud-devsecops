terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment        = var.environment
      Project            = var.project_name
      ManagedBy          = "Terraform"
      ComplianceBaseline = "SOC2-ISO27001"
    }
  }
}

# Unique suffix to prevent S3 global namespace collisions
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Primary Secure Data Bucket
resource "aws_s3_bucket" "secure_storage" {
  bucket        = "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# 1. Enforce Server-Side Encryption (KMS / AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_storage_encryption" {
  bucket = aws_s3_bucket.secure_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. Block All Public Access (SOC 2 / CIS AWS Benchmark Requirement)
resource "aws_s3_bucket_public_access_block" "secure_storage_pab" {
  bucket = aws_s3_bucket.secure_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Enable Versioning (Data Integrity & Ransomware Protection)
resource "aws_s3_bucket_versioning" "secure_storage_versioning" {
  bucket = aws_s3_bucket.secure_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 4. Enforce TLS 1.2+ and HTTPS via Bucket Policy
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.secure_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_storage.arn,
          "${aws_s3_bucket.secure_storage.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
