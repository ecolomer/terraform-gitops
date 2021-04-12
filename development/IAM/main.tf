provider "aws" {
  region = "eu-west-1"
}
terraform {
  backend "s3" {
    bucket = "terraform-states-abaland"
    key    = "gitops-iam.tfstate"
    region = "eu-west-1"
    dynamodb_table = "terraform_gitops"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.13"
}
