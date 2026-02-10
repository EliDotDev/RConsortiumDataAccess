variable "user_pool_name" {
  type = string
}

variable "callback_url" {
  type = string
}

variable "logout_url" {
  type = string
}

variable "presignup_lambda_arn" {
  type = string
}

variable "presignup_lambda_name" {
  type = string
}

# --- Random suffix for the Cognito domain ---
resource "random_id" "domain_suffix" {
  byte_length = 4
}

# --- Cognito User Pool ---
resource "aws_cognito_user_pool" "main" {
  name = var.user_pool_name

  # Email-based sign-in
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  # Schema
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Pre sign-up trigger
  lambda_config {
    pre_sign_up = var.presignup_lambda_arn
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

# --- Allow Cognito to invoke the Lambda ---
resource "aws_lambda_permission" "cognito" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.presignup_lambda_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

# --- Cognito User Pool Domain (for Hosted UI) ---
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "dvc-portal-${random_id.domain_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# --- Cognito User Pool Client ---
resource "aws_cognito_user_pool_client" "main" {
  name         = "dvc-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth settings
  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = [var.callback_url]
  logout_urls   = [var.logout_url]

  # Token validity
  id_token_validity      = 8
  access_token_validity  = 8
  refresh_token_validity = 30

  token_validity_units {
    id_token      = "hours"
    access_token  = "hours"
    refresh_token = "days"
  }

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
}

# --- Cognito Identity Pool ---
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "dvc_identity_pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }
}

# --- Outputs ---
output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.main.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.main.id
}

output "domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

output "hosted_ui_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.main.id}&response_type=token&scope=openid+email+profile&redirect_uri=${var.callback_url}"
}

data "aws_region" "current" {}
