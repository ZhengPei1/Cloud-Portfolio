terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
	region     = var.REGION
}

variable "DOMAIN_NAME" {
  description = "The custom domain name for the portfolio."
  type        = string
}

variable "S3_BUCKET_NAME" {
  description = "S3 bucket name."
  type        = string
}

variable "REGION" {
  description = "The AWS region to deploy resources into."
  type        = string
}

variable "LAMBDA_FUNC_NAME" {
  description = "Lambda function name."
  type        = string
}

variable "LAMBDA_EXEC_ROLE_NAME" {
  description = "Lambda execution role name."
  type        = string
}

variable "API_NAME"{
  description = "Name of API Gateway Endpoint"
  type = string
}

data "aws_caller_identity" "current" {}
