terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
      # CloudFront only accepts ACM certificates from us-east-1, so the caller
      # must pass a provider configured for that region.
      configuration_aliases = [aws.us_east_1]
    }
  }
}
