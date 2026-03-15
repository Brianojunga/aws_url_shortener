resource "aws_lambda_function" "url_shortener" {
  function_name = "url_shortener"
  handler = "handler.lambda_handler"
  runtime = "python3.10"
  role = aws_iam_role.lambda_exec.arn
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout = 20
  memory_size = 128
}

# Create Lambda deployment package
data "archive_file" "lambda_zip"{
  type = "zip"
  source_dir = var.lambda_source_path
  output_path = "${path.module}/lambda.zip"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.url_shortener.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
          {
              Action = "sts:AssumeRole",
              Effect = "Allow",
              Principal = {
                  Service = "lambda.amazonaws.com"
              }
          }
      ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda_dynamodb_policy"
  role = aws_iam_role.lambda_exec.id

    policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = var.dynamodb_arn
      }
    ]
  })
}


# CloudWatch Logs policy
resource "aws_iam_role_policy" "lambda_logs" {
  name = "lambda-logs-policy"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


# X-Ray tracing policy
resource "aws_iam_role_policy" "lambda_xray" {
  name = "lambda-xray-policy"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}