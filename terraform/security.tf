# ---------------------------------------------------------------
# Segurança: Security Groups (stateful) e NACL (stateless)
# ---------------------------------------------------------------

# Firewall do futuro servidor web (subnet pública)
resource "aws_security_group" "web" {
  name        = "web-corporativa"
  description = "Permite somente trafego web"
  vpc_id      = aws_vpc.corporativa.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída aberta (padrão). Pode ser restringida em uma fase futura.
  egress {
    description = "Saida IPv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-web-corporativa"
  }
}

# Firewall do futuro servidor interno (subnet privada).
# SG encadeado: só aceita tráfego vindo do sg-web.
resource "aws_security_group" "app" {
  name        = "app-corporativa"
  description = "Servidor interno: aceita trafego somente do sg-web"
  vpc_id      = aws_vpc.corporativa.id

  ingress {
    description     = "Aplicacao vinda do sg-web"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Saida somente dentro da VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "sg-app-corporativa"
  }
}

# NACL da subnet privada. É stateless: o tráfego de resposta
# precisa ser liberado explicitamente nos dois sentidos.
# Tudo que não tem regra de allow cai na regra padrão (deny).
resource "aws_network_acl" "privada" {
  vpc_id     = aws_vpc.corporativa.id
  subnet_ids = [aws_subnet.privada.id]

  # Entrada: aplicação vinda da subnet pública
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = var.app_port
    to_port    = var.app_port
  }

  # Entrada: respostas de DNS (resolvedor da VPC)
  ingress {
    rule_no    = 110
    protocol   = "udp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Saída: respostas da aplicação para a subnet pública
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Saída: consultas DNS ao resolvedor da VPC
  egress {
    rule_no    = 110
    protocol   = "udp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 53
    to_port    = 53
  }

  tags = {
    Name = "nacl-privada"
  }
}
