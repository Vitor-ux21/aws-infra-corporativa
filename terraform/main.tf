terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "corporativa" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc-corporativa"
    Environment = "laboratorio"
    Project     = "aws-infra-corporativa"
  }
}

resource "aws_subnet" "publica" {
  vpc_id                  = aws_vpc.corporativa.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-publica"
  }
}

resource "aws_subnet" "privada" {

  vpc_id     = aws_vpc.corporativa.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "subnet-privada"
  }
}
