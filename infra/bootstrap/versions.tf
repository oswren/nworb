terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bootstrap state lives in the bucket this stack creates. Credentials come
  # from AWS_PROFILE (backends can't read Terraform variables).
  backend "s3" {
    bucket       = "nworb-terraform-state-eu-west-2"
    key          = "bootstrap/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
