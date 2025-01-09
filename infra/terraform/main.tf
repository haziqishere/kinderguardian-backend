terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
    backend "s3" {
    bucket = "kinderguardian-terraform-state"
    key = "terraform.tfstate"
    region = "ap-southeast-5"
    encrypt = true
    dynamodb_table = "terraform-lock"
  }

}

provider "aws" {
  region = "ap-southeast-5"  # Malaysia region
}

