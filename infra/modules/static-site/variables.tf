variable "bucket_name" {
  description = "Globally unique name for the private S3 bucket holding the built site."
  type        = string
}

variable "domain_names" {
  description = "Domains the site is served on. The first is the certificate's primary name; the rest become subject alternative names."
  type        = list(string)

  validation {
    condition     = length(var.domain_names) > 0
    error_message = "At least one domain name is required."
  }
}
