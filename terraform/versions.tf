terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Tags aplicadas automaticamente a todos os recursos
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
    }
  }
}
