output "cloudfront_domain_name" {
    description = "Cloudfront url"
    value = aws_cloudfront_distribution.api_distribution.domain_name
}