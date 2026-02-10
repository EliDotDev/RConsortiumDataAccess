variable "bucket_name" {
  type = string
}

variable "user_pool_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "identity_pool_id" {
  type = string
}

variable "cognito_domain" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "dvc_bucket_name" {
  type = string
}

variable "dvc_endpoint_url" {
  type = string
}

# --- S3 Bucket for Static Website ---
resource "aws_s3_bucket" "callback" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "callback" {
  bucket = aws_s3_bucket.callback.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "callback" {
  bucket = aws_s3_bucket.callback.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "callback" {
  bucket = aws_s3_bucket.callback.id

  depends_on = [aws_s3_bucket_public_access_block.callback]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.callback.arn}/*"
      }
    ]
  })
}

# --- Upload the callback HTML page ---
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.callback.id
  key          = "index.html"
  content_type = "text/html"

  content = templatefile("${path.module}/index.html.tftpl", {
    aws_region       = var.aws_region
    user_pool_id     = var.user_pool_id
    client_id        = var.client_id
    identity_pool_id = var.identity_pool_id
    cognito_domain   = var.cognito_domain
    dvc_bucket_name  = var.dvc_bucket_name
    dvc_endpoint_url = var.dvc_endpoint_url
  })
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.callback.website_endpoint
}
