terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

   cloud {
     organization = "EliDotDev"
     workspaces {
       name = "RConsortiumPilotsApp"
     }
   }
}

provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Random suffix for globally unique names ---
resource "random_id" "suffix" {
  byte_length = 4
}

# --- S3 Bucket for DVC Data ---
module "dvc_bucket" {
  source      = "./modules/s3"
  bucket_name = var.dvc_bucket_name
}

# --- Lambda for Cognito Pre-Sign-Up Trigger ---
module "presignup_lambda" {
  source         = "./modules/lambda"
  function_name  = "cognito-presignup-${random_id.suffix.hex}"
  allowed_emails = var.allowed_emails
}

# --- Cognito User Pool & Identity Pool ---
module "cognito" {
  source                = "./modules/cognito"
  user_pool_name        = "dvc-users-${random_id.suffix.hex}"
  callback_url          = "https://${module.callback_page.website_endpoint}/index.html"
  logout_url            = "https://${module.callback_page.website_endpoint}/index.html"
  presignup_lambda_arn  = module.presignup_lambda.function_arn
  presignup_lambda_name = module.presignup_lambda.function_name
}

# --- IAM Roles for Cognito Identity Pool ---
module "iam" {
  source              = "./modules/iam"
  identity_pool_id    = module.cognito.identity_pool_id
  dvc_bucket_arn      = module.dvc_bucket.bucket_arn
  credential_duration = var.credential_duration_seconds
}

# --- Attach IAM Roles to Identity Pool ---
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = module.cognito.identity_pool_id

  roles = {
    "authenticated" = module.iam.authenticated_role_arn
  }
}

# --- Static Callback Page ---
module "callback_page" {
  source            = "./modules/callback-page"
  bucket_name       = "dvc-callback-${random_id.suffix.hex}"
  user_pool_id      = module.cognito.user_pool_id
  client_id         = module.cognito.client_id
  identity_pool_id  = module.cognito.identity_pool_id
  cognito_domain    = module.cognito.domain
  aws_region        = var.aws_region
  dvc_bucket_name   = var.dvc_bucket_name
  dvc_endpoint_url  = "https://s3.${var.aws_region}.amazonaws.com"
}
