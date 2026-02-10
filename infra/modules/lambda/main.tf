variable "function_name" {
  type = string
}

variable "allowed_emails" {
  type = list(string)
}

# --- Lambda Function Code ---
data "archive_file" "presignup" {
  type        = "zip"
  output_path = "${path.module}/presignup.zip"

  source {
    content  = <<-EOF
      exports.handler = async (event) => {
        const allowedEmails = ${jsonencode(var.allowed_emails)};
        const email = event.request.userAttributes.email.toLowerCase();
        
        if (!allowedEmails.map(e => e.toLowerCase()).includes(email)) {
          throw new Error("Email not in the allowed list. Contact the administrator to request access.");
        }
        
        // Auto-confirm the email to simplify the sign-up flow
        event.response.autoConfirmUser = true;
        event.response.autoVerifyEmail = true;
        
        return event;
      };
    EOF
    filename = "index.js"
  }
}

# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Lambda Function ---
resource "aws_lambda_function" "presignup" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 5
  filename         = data.archive_file.presignup.output_path
  source_code_hash = data.archive_file.presignup.output_base64sha256
}

output "function_arn" {
  value = aws_lambda_function.presignup.arn
}

output "function_name" {
  value = aws_lambda_function.presignup.function_name
}
