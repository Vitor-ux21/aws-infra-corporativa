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
# Internet Gateway da VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.corporativa.id

  tags = {
    Name = "igw-corporativa"
  }
}

# Tabela de rotas pública
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.corporativa.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-publica"
  }
}

resource "aws_route_table_association" "publica" {
  subnet_id      = aws_subnet.publica.id
  route_table_id = aws_route_table.publica.id
}

# Tabela de rotas privada
resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.corporativa.id

  tags = {
    Name = "rt-privada"
  }
}

resource "aws_route_table_association" "privada" {
  subnet_id      = aws_subnet.privada.id
  route_table_id = aws_route_table.privada.id
}
