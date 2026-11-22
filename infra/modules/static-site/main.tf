# The static site: private bucket, access control, certificate, and the
# CloudFront distribution that serves the bucket over HTTPS.
#
# The certificate is validated through DNS records added in Cloudflare by hand
# (or with the cf CLI), so the validation resource below doesn't create them.

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# The bucket is never public. Only the CloudFront distribution may read it,
# via the policy added in piece 2.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control: lets CloudFront sign its requests to the bucket
# with SigV4. This replaces the older Origin Access Identity.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = var.bucket_name
  description                       = "Signs CloudFront requests to ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront requires its certificate in us-east-1, whatever region the rest
# of the stack uses.
resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1

  domain_name               = var.domain_names[0]
  subject_alternative_names = slice(var.domain_names, 1, length(var.domain_names))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Waits until ACM reports the certificate ISSUED. The records were created
# earlier, so this returns straight away.
resource "aws_acm_certificate_validation" "site" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.site.domain_validation_options : dvo.resource_record_name]
}

# Caching and security headers use AWS managed policies, so no custom
# policy objects are needed.
locals {
  managed_cache_policy_caching_optimized = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  managed_response_headers_security      = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  s3_origin_id                           = "site-s3"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.bucket_name} static site"
  default_root_object = "index.html"
  aliases             = var.domain_names
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id           = local.s3_origin_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = local.managed_cache_policy_caching_optimized
    response_headers_policy_id = local.managed_response_headers_security
  }

  # Client-side routing: a missing object (S3 returns 403) or a 404 is served
  # as index.html, so deep links like /projects reach the React router.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Only this distribution may read the bucket, and only through OAC.
data "aws_iam_policy_document" "site_bucket" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.site]
}
