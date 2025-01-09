# infra/terraform/s3.tf

# S3 bucket for storing student images
resource "aws_s3_bucket" "student_images" {
  bucket = "${var.project_name}-student-images-${var.environment}"

  # Force destroy for development - REMOVE THIS FOR PRODUCTION
  force_destroy = var.environment == "dev" ? true : false
}

# Enable versioning for safety
resource "aws_s3_bucket_versioning" "student_images" {
  bucket = aws_s3_bucket.student_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "student_images" {
  bucket = aws_s3_bucket.student_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "student_images" {
  bucket = aws_s3_bucket.student_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optional: Lifecycle rule to delete old versions after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "student_images" {
  bucket = aws_s3_bucket.student_images.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# IAM user for programmatic access
resource "aws_iam_user" "app_user" {
  name = "${var.project_name}-app-user-${var.environment}"
}

# IAM policy for S3 access
resource "aws_iam_user_policy" "app_user_policy" {
  name = "${var.project_name}-app-policy-${var.environment}"
  user = aws_iam_user.app_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.student_images.arn,
          "${aws_s3_bucket.student_images.arn}/*"
        ]
      }
    ]
  })
}

# Access keys for the IAM user
resource "aws_iam_access_key" "app_user" {
  user = aws_iam_user.app_user.name
}

# Output the bucket name and access credentials
output "bucket_name" {
  value = aws_s3_bucket.student_images.id
}

output "access_key_id" {
  value     = aws_iam_access_key.app_user.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.app_user.secret
  sensitive = true
}