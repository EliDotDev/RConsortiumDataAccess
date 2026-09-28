variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket" "dvc" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "dvc" {
  bucket = aws_s3_bucket.dvc.id

  depends_on = [aws_s3_bucket_public_access_block.dvc]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject-tf"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject",
          "s3:ListBucket"
          ]
        Resource  = [
          "${aws_s3_bucket.dvc.arn}/*",
          "${aws_s3_bucket.dvc.arn}"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "dvc" {
  bucket = aws_s3_bucket.dvc.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dvc" {
  bucket = aws_s3_bucket.dvc.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dvc" {
  bucket = aws_s3_bucket.dvc.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

output "bucket_arn" {
  value = aws_s3_bucket.dvc.arn
}

output "bucket_name" {
  value = aws_s3_bucket.dvc.bucket
}
