# ---------------------------------------------------------------
# Rede: VPC, subnets, Internet Gateway e tabelas de rotas
# ---------------------------------------------------------------

resource "aws_vpc" "corporativa" {
  #checkov:skip=CKV2_AWS_11:Flow Logs exigem destino (CloudWatch ou S3) com custo; planejado para a Fase 6 do roadmap
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-corporativa"
  }
}

# Subnet pública: tem rota para o Internet Gateway.
# map_public_ip_on_launch = false: instâncias NÃO recebem IP público
# automaticamente; use um Elastic IP quando subir o servidor web.
resource "aws_subnet" "publica" {
  vpc_id                  = aws_vpc.corporativa.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-publica"
    Tier = "publica"
  }
}

# Subnet privada: sem rota para a internet.
resource "aws_subnet" "privada" {
  vpc_id            = aws_vpc.corporativa.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "subnet-privada"
    Tier = "privada"
  }
}

# Internet Gateway da VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.corporativa.id

  tags = {
    Name = "igw-corporativa"
  }
}

# Tabela de rotas pública: rota padrão pelo IGW
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

# Tabela de rotas privada: somente a rota local (automática)
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

# Security Group padrão da VPC sem nenhuma regra: bloqueia todo o tráfego.
# Recursos devem usar sempre um Security Group próprio.
resource "aws_default_security_group" "padrao" {
  vpc_id = aws_vpc.corporativa.id

  tags = {
    Name = "sg-padrao-bloqueado"
  }
}
