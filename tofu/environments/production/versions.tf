terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — bucket + lock table come from bootstrap/state/.
  # Configured via `tofu init -backend-config=backend.hcl` (see README).
  backend "s3" {}
}

# No default_tags here, unlike sandbox: this environment adopts
# resources that already exist, and the first apply must change
# nothing on them. Adding Project/Environment/ManagedBy tags is a
# follow-up once adoption has landed cleanly (see README).
provider "aws" {
  region = var.region
}
