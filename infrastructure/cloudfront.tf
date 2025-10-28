# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${local.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${local.name}"
  default_root_object = ""

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${local.name}"

    forwarded_values {
      query_string = true
      headers      = ["X-Forwarded-For", "X-Forwarded-Proto", "X-Forwarded-Port"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # Cache behavior for health check endpoint
  ordered_cache_behavior {
    path_pattern     = "/health"
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    target_origin_id = "ALB-${local.name}"

    forwarded_values {
      query_string = false
      headers      = ["X-Forwarded-For"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.common_tags

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
