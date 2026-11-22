# GitHub Actions -> AWS federation, so CI can assume a role with no stored keys.
#
# The OIDC provider is account-wide (one per account), so it lives here.
# The Wynforge bootstrap looks it up with a data source.

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to assume the deploy role."
  type        = string
  default     = "oswren/nworb"
}

variable "github_branch" {
  description = "Branch whose workflow runs may assume the deploy role."
  type        = string
  default     = "main"
}

# The repository uses immutable subject claims, so the OIDC `sub` includes the
# numeric owner and repo IDs: repo:<owner>@<owner_id>/<repo>@<repo_id>:...
# IDs stay the same if the repo is renamed, which makes the trust stricter.
variable "github_owner_id" {
  description = "Numeric GitHub owner (user or org) ID, used in the immutable OIDC subject."
  type        = string
  default     = "109461720"
}

variable "github_repo_id" {
  description = "Numeric GitHub repository ID, used in the immutable OIDC subject."
  type        = string
  default     = "1467957395"
}

locals {
  github_owner = split("/", var.github_repo)[0]
  github_name  = split("/", var.github_repo)[1]
  github_sub   = "repo:${local.github_owner}@${var.github_owner_id}/${local.github_name}@${var.github_repo_id}:ref:refs/heads/${var.github_branch}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's published root CA thumbprint. Required by the API.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    sid     = "GitHubActionsOnBranch"
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
      values   = [local.github_sub]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "nworb-github-deploy"
  description          = "Assumed by GitHub Actions on the nworb repo's main branch."
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust.json
  max_session_duration = 3600
}

# Phase 0 scope: state access only. Extended in Phase 1 when the site's
# S3, CloudFront and ACM resources exist.
data "aws_iam_policy_document" "deploy_state" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "ReadWriteStateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }
}

resource "aws_iam_role_policy" "deploy_state" {
  name   = "terraform-state"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_state.json
}

# Site publishing: sync the built app to the site bucket and invalidate the
# distribution. Scoped to those two resources only. Identifiers, not secrets.
variable "site_bucket_name" {
  description = "Bucket the built personal site is published into."
  type        = string
  default     = "nworb-personal-site-prod"
}

variable "site_distribution_id" {
  description = "CloudFront distribution serving the personal site."
  type        = string
  default     = "E1C7GZ50C64M02"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "deploy_site" {
  statement {
    sid       = "ListSiteBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.site_bucket_name}"]
  }

  statement {
    sid       = "PublishSiteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.site_bucket_name}/*"]
  }

  statement {
    sid     = "InvalidateSiteCache"
    actions = ["cloudfront:CreateInvalidation"]
    resources = [
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.site_distribution_id}",
    ]
  }
}

resource "aws_iam_role_policy" "deploy_site" {
  name   = "site-publish"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_site.json
}

output "deploy_role_arn" {
  description = "Role ARN for the GitHub Actions workflow (aws-actions/configure-aws-credentials)."
  value       = aws_iam_role.deploy.arn
}
