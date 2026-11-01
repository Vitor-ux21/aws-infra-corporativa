# Testes da rede com provider simulado: nenhum recurso real é criado
# e nenhuma credencial AWS é necessária.

mock_provider "aws" {
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/vpc/flow-logs/vpc-corporativa"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/role-flow-logs-corporativa"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  availability_zone   = "us-east-1a"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  app_port            = 8080
}

run "enderecamento" {
  command = apply

  assert {
    condition     = aws_vpc.corporativa.cidr_block == "10.0.0.0/16"
    error_message = "A VPC deveria usar 10.0.0.0/16."
  }

  assert {
    condition     = aws_subnet.publica.cidr_block == "10.0.1.0/24"
    error_message = "A subnet pública deveria usar 10.0.1.0/24."
  }

  assert {
    condition     = aws_subnet.privada.cidr_block == "10.0.2.0/24"
    error_message = "A subnet privada deveria usar 10.0.2.0/24."
  }
}

run "rota_publica_pelo_igw" {
  command = apply

  assert {
    condition = length([
      for r in aws_route_table.publica.route : r
      if r.cidr_block == "0.0.0.0/0" && r.gateway_id == aws_internet_gateway.igw.id
    ]) == 1
    error_message = "A route table pública deveria ter a rota padrão pelo Internet Gateway."
  }
}

run "subnet_privada_sem_saida_para_internet" {
  command = apply

  assert {
    condition = length([
      for r in aws_route_table.privada.route : r
      if r.cidr_block == "0.0.0.0/0"
    ]) == 0
    error_message = "A route table privada não pode ter rota padrão para a internet."
  }
}

run "associacoes_de_route_table" {
  command = apply

  assert {
    condition     = aws_route_table_association.publica.route_table_id == aws_route_table.publica.id
    error_message = "A subnet pública deveria usar a route table pública."
  }

  assert {
    condition     = aws_route_table_association.privada.route_table_id == aws_route_table.privada.id
    error_message = "A subnet privada deveria usar a route table privada."
  }
}

run "sem_ip_publico_automatico" {
  command = apply

  assert {
    condition     = aws_subnet.publica.map_public_ip_on_launch == false
    error_message = "A subnet pública não deveria atribuir IP público automaticamente."
  }

  assert {
    condition     = coalesce(aws_subnet.privada.map_public_ip_on_launch, false) == false
    error_message = "A subnet privada não deveria atribuir IP público automaticamente."
  }
}

run "portas_administrativas_fechadas" {
  command = apply

  assert {
    condition = length([
      for r in aws_security_group.web.ingress : r
      if contains(coalesce(r.cidr_blocks, []), "0.0.0.0/0") &&
      ((r.from_port <= 22 && r.to_port >= 22) || (r.from_port <= 3389 && r.to_port >= 3389))
    ]) == 0
    error_message = "O SG web não pode expor SSH (22) ou RDP (3389) para a internet."
  }

  assert {
    condition = length([
      for r in aws_security_group.app.ingress : r
      if contains(coalesce(r.cidr_blocks, []), "0.0.0.0/0")
    ]) == 0
    error_message = "O SG app não pode aceitar tráfego de 0.0.0.0/0."
  }
}

run "sg_padrao_bloqueado" {
  command = apply

  assert {
    condition     = length(aws_default_security_group.padrao.ingress) == 0 && length(aws_default_security_group.padrao.egress) == 0
    error_message = "O Security Group padrão deveria ficar sem regras."
  }
}

run "nacl_privada_sem_entrada_aberta" {
  command = apply

  assert {
    condition = length([
      for r in aws_network_acl.privada.ingress : r
      if r.cidr_block == "0.0.0.0/0"
    ]) == 0
    error_message = "A NACL privada não pode permitir entrada de 0.0.0.0/0."
  }
}

run "flow_logs" {
  command = apply

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs.retention_in_days == 365
    error_message = "O log group dos Flow Logs deveria reter 365 dias."
  }

  assert {
    condition     = aws_flow_log.vpc.traffic_type == "ALL"
    error_message = "Os Flow Logs deveriam registrar todo o tráfego (ALL)."
  }
}
