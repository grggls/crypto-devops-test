terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "ap-southeast-2"
  access_key = "AKIA1234567890123456"
  secret_key = "qwertyabcdefghijklmnopqr0x10101"
}
module "prod-ci-module" {
  source = "./terraform-module"
}
