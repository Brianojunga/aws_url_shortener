variable "lambda_source_path" {
  description = "Path to the Lambda function source code"
  type        = string
}

variable "dynamodb_arn" {
    description = "DynamoDB table ARN for lambda permissions"
    type = string
}
