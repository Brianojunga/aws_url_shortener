resource "aws_api_gateway_rest_api" "url_shortener_api" {
    name = "URL Shortener API"
    description = "API for URL shortener service"

    endpoint_configuration {
        types = ["REGIONAL"]
  }
}

# Create /shorten resource
resource "aws_api_gateway_resource" "shorten" {
    rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
    parent_id = aws_api_gateway_rest_api.url_shortener_api.root_resource_id
    path_part = "shorten"
}

# Create POST method for /shorten
resource "aws_api_gateway_method" "shorten_post" {
    rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
    resource_id = aws_api_gateway_resource.shorten.id
    http_method = "POST"
    authorization = "NONE"
}

# Integrate POST /shorten with Lambda
resource "aws_api_gateway_integration" "shorten_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id             = aws_api_gateway_resource.shorten.id
  http_method             = aws_api_gateway_method.shorten_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Create /{shortCode} resource (path parameter)
resource "aws_api_gateway_resource" "redirect" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  parent_id   = aws_api_gateway_rest_api.url_shortener_api.root_resource_id
  path_part   = "{shortCode}"
}

# create GET method for /{shortcode}
resource "aws_api_gateway_method" "redirect_get" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id   = aws_api_gateway_resource.redirect.id
  http_method   = "GET"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.path.shortCode" = true
  }
}

# Intergrate GET /{shortCode} with Lambda
resource "aws_api_gateway_integration" "redirect_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id             = aws_api_gateway_resource.redirect.id
  http_method             = aws_api_gateway_method.redirect_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# OPTIONS method for /shorten (CORS preflight)
resource "aws_api_gateway_method" "shorten_options" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id   = aws_api_gateway_resource.shorten.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "shorten_options" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id = aws_api_gateway_resource.shorten.id
  http_method = aws_api_gateway_method.shorten_options.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "shorten_options" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id = aws_api_gateway_resource.shorten.id
  http_method = aws_api_gateway_method.shorten_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "shorten_options" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  resource_id = aws_api_gateway_resource.shorten.id
  http_method = aws_api_gateway_method.shorten_options.http_method
  status_code = aws_api_gateway_method_response.shorten_options.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

#Deploy API to 'prod' stage
resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener_api.id
  
  # Force redeployment when API changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.shorten.id,
      aws_api_gateway_method.shorten_post.id,
      aws_api_gateway_integration.shorten_lambda.id,
      aws_api_gateway_resource.redirect.id,
      aws_api_gateway_method.redirect_get.id,
      aws_api_gateway_integration.redirect_lambda.id,
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

#Create 'prod' stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.url_shortener_api.id
  stage_name    = "prod"
  
  # Enable CloudWatch logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
  
  # Enable X-Ray tracing
  xray_tracing_enabled = true
}


#cloud watch log group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway" {
    name = "/aws/apigateway/url-shortener"
    retention_in_days = 7
}

#create usage plan
resource "aws_api_gateway_usage_plan" "main" {
  name = "url-shortener-usage-plan"
  
  api_stages {
    api_id = aws_api_gateway_rest_api.url_shortener_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
  
  quota_settings {
    limit  = 10000
    period = "MONTH"
  }
  
  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }
}