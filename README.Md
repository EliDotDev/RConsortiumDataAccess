# R Consortium Pilots — DVC Data Portal

Terraform configuration that sets up a self-service credential portal for cross-company DVC collaboration using AWS Cognito and S3.

## Architecture

- **S3 Bucket** (`rconsortium-pilots`) — DVC data storage
- **Cognito User Pool** — email-based authentication with pre-sign-up Lambda that restricts registration to allowed emails
- **Cognito Identity Pool** — exchanges Cognito tokens for temporary AWS credentials scoped to the S3 bucket
- **Static Callback Page** — hosted on S3, provides a web UI where users sign in and receive their temporary credentials + DVC configuration commands

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.5.0
- Terraform Cloud workspace (or update backend config)

## Setup

1. **Clone and configure backend**

   Edit the `cloud {}` block in `main.tf` with your Terraform Cloud organization and workspace.

2. **Create your tfvars file**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars` with your allowed email list:

   ```hcl
   allowed_emails = [
     "alice@company-a.com",
     "bob@company-b.com",
   ]
   ```

3. **Deploy**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Share the login URL**

   After apply, Terraform outputs the `cognito_hosted_ui_url`. Share this link with your collaborators.

## User Workflow

1. User visits the login URL
2. First-time users click "Sign up" and register with their email + password (only allowed emails can register)
3. After signing in, they're redirected to the credential page
4. The page displays temporary AWS credentials (valid for 8 hours) and ready-to-paste DVC commands
5. When credentials expire, they return to the page and sign in again

## Managing Access

**Add a user:** Add their email to `allowed_emails` in `terraform.tfvars` and run `terraform apply`.

**Remove a user:** Remove their email from the list, run `terraform apply`, then disable/delete their account in the Cognito console:

```bash
aws cognito-idp admin-disable-user \
  --user-pool-id <pool-id> \
  --username <their-email>
```

## Outputs

| Output | Description |
|--------|-------------|
| `cognito_hosted_ui_url` | Login URL to share with collaborators |
| `callback_page_url` | Direct URL to the credential page |
| `dvc_bucket_name` | S3 bucket name for DVC |
| `cognito_user_pool_id` | Cognito User Pool ID (for admin tasks) |
| `identity_pool_id` | Cognito Identity Pool ID |

