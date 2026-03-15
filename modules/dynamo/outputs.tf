output "table_arn" {
    description = "Dynamo DB table ARN"
    value = aws_dynamodb_table.url_shortener.arn
}