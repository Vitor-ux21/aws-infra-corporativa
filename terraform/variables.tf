variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Zona de disponibilidade das subnets"
  type        = string
  default     = "us-east-1a"
}

variable "project_name" {
  description = "Nome do projeto (usado nas tags)"
  type        = string
  default     = "aws-infra-corporativa"
}

variable "environment" {
  description = "Ambiente (usado nas tags)"
  type        = string
  default     = "laboratorio"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr deve ser um CIDR IPv4 válido, por exemplo 10.0.0.0/16."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "public_subnet_cidr deve ser um CIDR IPv4 válido, por exemplo 10.0.1.0/24."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR da subnet privada"
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_subnet_cidr))
    error_message = "private_subnet_cidr deve ser um CIDR IPv4 válido, por exemplo 10.0.2.0/24."
  }
}

variable "app_port" {
  description = "Porta TCP do servidor interno (camada privada)"
  type        = number
  default     = 8080
}
