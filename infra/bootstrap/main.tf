variable "region" {
  description = "Primary AWS region for all resources."
  type        = string
  default     = "eu-west-2"
}

variable "profile" {
  description = "Local AWS CLI profile to authenticate with (SSO)."
  type        = string
  default     = "admin-nworb"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
  default     = "nworb-terraform-state-eu-west-2"
}

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      Project   = "nworb-infra"
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}

# Bucket that stores Terraform state for this repo's stacks.
# Locking uses S3 native lockfiles (use_lockfile = true in backend blocks),
# so no DynamoDB table is needed.
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Deny any request that isn't over TLS.
data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_tls_only.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

output "state_bucket" {
  description = "Name of the Terraform state bucket."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_region" {
  value = aws_s3_bucket.state.region
}

variable "budget_alert_email" {
  description = "Email address for budget alerts. Set in terraform.tfvars (git-ignored), not here."
  type        = string
  sensitive   = true
}

# Monthly cost guardrail. Emails at 80% of actual spend and at 100% of forecast.
resource "aws_budgets_budget" "monthly" {
  name         = "nworb-monthly-cap"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
