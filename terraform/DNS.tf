resource "aws_route53_zone" "R53_domain" {
  name = var.DOMAIN_NAME
}

resource "aws_route53_record" "cloudfront_a" {
  zone_id = aws_route53_zone.R53_domain.zone_id
  name    = aws_route53_zone.R53_domain.name
  type    = "A" #IPv4

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_aaaa" {
  zone_id = aws_route53_zone.R53_domain.zone_id
  name    = aws_route53_zone.R53_domain.name
  type     = "AAAA" #IPv6
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_acm_certificate" "cert" {
  domain_name       = var.DOMAIN_NAME
  validation_method = "DNS"
}


# Set up Cloudfront
resource "aws_cloudfront_origin_access_control" "s3_distribution" {
  name                              = "default-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3_web_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_distribution.id
    origin_id                = aws_s3_bucket.s3_web_bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.DOMAIN_NAME]


  default_cache_behavior {
    # Only allow methods needed for reading content
    allowed_methods    = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.s3_web_bucket.id

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  price_class = "PriceClass_100"

  tags = {
    Name = "cloud-portfolio"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

