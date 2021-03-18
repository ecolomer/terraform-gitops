provider "aws" {
  region = "eu-west-1"
}
terraform {
  backend "s3" {
    bucket = "terraform-states"
    key    = "gitops.tfstate"
    region = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.13"
}
