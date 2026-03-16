output "api_gateway_invoke_url" {
    description = "API Gateway invoke URL"
    value = aws_api_gateway_stage.prod.invoke_url
}

output "api_gateway_execution_arn" {
  description = "ARN of the API Gateway execution for Lambda permissions"
  value       = "${aws_api_gateway_rest_api.url_shortener_api.execution_arn}/*/*"
}