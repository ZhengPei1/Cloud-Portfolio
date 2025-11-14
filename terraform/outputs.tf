output "api_endpoint" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/Production/"
}

output "cloudfront_domain_name" {
  description = "CF domain name"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "website_url" {
  description = "Website Domain Name."
  value       = "https://${var.DOMAIN_NAME}"
}