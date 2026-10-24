# ---------------------------------------------------------------
# Segurança: Security Groups (stateful) e NACL (stateless)
# ---------------------------------------------------------------

# Firewall do futuro servidor web (subnet pública)
resource "aws_security_group" "web" {
  #checkov:skip=CKV_AWS_260:Servidor web publico: a porta 80 fica aberta para redirecionar para HTTPS
  #checkov:skip=CKV2_AWS_5:O servidor web sera criado em uma fase futura do roadmap
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

  # Saída restrita ao necessário (não usa a regra padrão "todo tráfego").
  # O DNS da VPC (base + 2) não é filtrado por Security Group.
  egress {
    description = "HTTPS para a internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP para a internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Referência por CIDR (e não por Security Group) para evitar dependência
  # circular com o sg-app, que referencia o sg-web na entrada.
  egress {
    description = "Aplicacao na subnet privada"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  tags = {
    Name = "sg-web-corporativa"
  }
}

# Firewall do futuro servidor interno (subnet privada).
# SG encadeado: só aceita tráfego vindo do sg-web.
resource "aws_security_group" "app" {
  #checkov:skip=CKV2_AWS_5:O servidor interno sera criado em uma fase futura do roadmap
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
# Obs.: a NACL não filtra o DNS da VPC (Route 53 Resolver, base + 2),
# por isso não há regra para DNS aqui.
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

  # Saída: respostas da aplicação para a subnet pública
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "nacl-privada"
  }
}
