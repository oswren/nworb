output "bucket_name" {
  description = "Bucket the build is synced into."
  value       = aws_s3_bucket.site.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.site.arn
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

# The target for the apex and www CNAMEs in Cloudflare (DNS only).
output "distribution_domain_name" {
  description = "CNAME target for nworb.cloud and www.nworb.cloud in Cloudflare."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "origin_access_control_id" {
  value = aws_cloudfront_origin_access_control.site.id
}

output "certificate_arn" {
  description = "ACM certificate ARN (us-east-1). Used by CloudFront once validated."
  value       = aws_acm_certificate.site.arn
}

# DNS records to add in Cloudflare (DNS only, not proxied) so ACM can validate
# the certificate. Keyed by domain name.
output "certificate_validation_records" {
  description = "CNAME records to add in Cloudflare for ACM DNS validation."
  value = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}
