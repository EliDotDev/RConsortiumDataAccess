variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "dvc_bucket_name" {
  description = "Name of the S3 bucket for DVC data"
  type        = string
  default     = "rconsortium-pilots"
}

variable "allowed_emails" {
  description = "List of email addresses allowed to register"
  type        = list(string)
}

variable "credential_duration_seconds" {
  description = "Duration of temporary credentials in seconds (max 43200 = 12 hours)"
  type        = number
  default     = 28800 # 8 hours
}
