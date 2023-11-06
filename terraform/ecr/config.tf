
# Would I do this under any circumstances if I had more than 3 hours?  
## No
terraform {
  required_version = "1.6.0"
  # Really you ought to clean this up and use a remote backend, but this is an interview and I spin this up A LOT, then run aws-nuke on the account
  backend "s3" {
    bucket = "meyerkev-terraform-state"
    key    = "inadev-interview-ecr-repos.tfstate"
    region = "us-east-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Terraform = "true"
    }
  }
}
