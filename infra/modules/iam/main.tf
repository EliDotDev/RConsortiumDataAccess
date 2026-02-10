variable "identity_pool_id" {
  type = string
}

variable "dvc_bucket_arn" {
  type = string
}

variable "credential_duration" {
  type    = number
  default = 28800
}

# --- Authenticated IAM Role ---
resource "aws_iam_role" "authenticated" {
  name = "cognito-dvc-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = var.identity_pool_id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  max_session_duration = var.credential_duration
}

# --- S3 Access Policy ---
resource "aws_iam_role_policy" "dvc_s3_access" {
  name = "dvc-s3-access"
  role = aws_iam_role.authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = [
          var.dvc_bucket_arn,
          "${var.dvc_bucket_arn}/*",
        ]
      }
    ]
  })
}

output "authenticated_role_arn" {
  value = aws_iam_role.authenticated.arn
}
