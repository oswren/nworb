terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "nworb-terraform-state-eu-west-2"
    key          = "site/prod/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

variable "profile" {
  description = "Local AWS CLI profile. Leave null in CI (OIDC credentials) and set AWS_PROFILE locally."
  type        = string
  default     = null
}

provider "aws" {
  region  = "eu-west-2"
  profile = var.profile

  default_tags {
    tags = {
      Project   = "nworb"
      Stack     = "site-prod"
      ManagedBy = "terraform"
    }
  }
}

# Used only for the ACM certificate, which CloudFront requires in us-east-1.
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.profile

  default_tags {
    tags = {
      Project   = "nworb"
      Stack     = "site-prod"
      ManagedBy = "terraform"
    }
  }
}

module "site" {
  source = "../../modules/static-site"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  bucket_name  = "nworb-personal-site-prod"
  domain_names = ["nworb.cloud", "www.nworb.cloud"]
}

output "bucket_name" {
  value = module.site.bucket_name
}

output "distribution_domain_name" {
  description = "CNAME target for nworb.cloud and www in Cloudflare (DNS only)."
  value       = module.site.distribution_domain_name
}

output "certificate_validation_records" {
  description = "Add each of these as a DNS-only CNAME in Cloudflare."
  value       = module.site.certificate_validation_records
}
