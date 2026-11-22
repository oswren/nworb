# Role for the Terraform apply workflow (.github/workflows/terraform-apply.yml).
#
# Trust is limited to the GitHub `production` environment. That environment
# has required reviewers, so the role can only be assumed after approval.
# The bootstrap stack is NOT applied from CI: it owns the deploy roles and
# their trust policies, and CI must not be able to change those.

data "aws_iam_policy_document" "terraform_apply_trust" {
  statement {
    sid     = "GitHubEnvironmentProduction"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.github_owner}@${var.github_owner_id}/${local.github_name}@${var.github_repo_id}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "terraform_apply" {
  name                 = "nworb-terraform-apply"
  description          = "Applies the nworb prod stack from CI after environment approval."
  assume_role_policy   = data.aws_iam_policy_document.terraform_apply_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "terraform_apply" {
  # Terraform state for the prod stack only (state and lock objects under site/prod/).
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["site/prod/*", "site/prod"]
    }
  }

  statement {
    sid       = "StateObjectsProdOnly"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/site/prod/*"]
  }

  # The site bucket the prod stack manages (bucket config and policy).
  statement {
    sid       = "ManageSiteBucket"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.site_bucket_name}", "arn:aws:s3:::${var.site_bucket_name}/*"]
  }

  # CloudFront has no resource-level create permission, so this is broad within
  # the account. Limit it further if you want, at the cost of more churn.
  statement {
    sid       = "ManageCloudFront"
    actions   = ["cloudfront:*"]
    resources = ["*"]
  }

  # ACM certificates are only used in us-east-1 (CloudFront requirement).
  statement {
    sid       = "ManageCertificatesUsEast1"
    actions   = ["acm:*"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }
}

resource "aws_iam_role_policy" "terraform_apply" {
  name   = "prod-stack"
  role   = aws_iam_role.terraform_apply.id
  policy = data.aws_iam_policy_document.terraform_apply.json
}

output "terraform_apply_role_arn" {
  description = "Role ARN for the terraform-apply workflow."
  value       = aws_iam_role.terraform_apply.arn
}
