provider aws {
    region = "us-east-1"
}

module "lambda" {
    source = "../modules/lambda"
    lambda_source_path = "../service"
    dynamodb_arn = module.dynamodb.table_arn
}

module "api_gateway" {
    source = "../modules/api_gateway"
    lambda_invoke_arn = module.lambda.lambda_invoke_arn
}

module "dynamodb" {
    source = "../modules/dynamo"
}

module "cloudfront" {
    source = "../modules/cloudfront"
    api_agw_invoke_url = module.api_gateway.api_gateway_invoke_url
}