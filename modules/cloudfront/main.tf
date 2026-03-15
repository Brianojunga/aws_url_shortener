resource "aws_cloudfront_distribution" "api_distribution" {
    enabled = true
    is_ipv6_enabled = true
    comment = "CloudFront distribution for API Gateway"

    origin {
        domain_name = var.api_agw_invoke_url
        origin_id = "api-gateway-origin"

        custom_origin_config {
          http_port = 80
          https_port = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols = ["TLSv1.2"]
        }
    }
    default_cache_behavior {
      target_origin_id = "api-gateway-origin"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = [
        "GET",
        "POST",
        "OPTIONS",
        "HEAD"
      ]

      cached_methods = [
        "GET",
        "HEAD"
      ]

      forwarded_values {
        query_string = true

        headers = ["Authorization"]

        cookies {
          forward = "all"
        }
      }

      min_ttl = 0
      default_ttl = 0
      max_ttl = 0
    }

    viewer_certificate {
      cloudfront_default_certificate = true
    }

    restrictions {
      geo_restriction {
        restriction_type = "none"
      }
    }
}