output "api_gateway_invoke_url" {
    description = "API Gateway invoke URL"
    value = aws_api_gateway_stage.prod.invoke_url
}