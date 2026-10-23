# 03 - Tabelas de roteamento

Fonte: `terraform/*.tf` (recursos `aws_route_table`, `aws_route_table_association` e `aws_internet_gateway`).

## 1. Visão geral

A VPC `vpc-corporativa` (10.0.0.0/16) tem duas route tables personalizadas, uma para cada subnet. Toda route table da AWS recebe automaticamente a rota **local**, que garante a comunicação entre todas as sub-redes da própria VPC. Essa rota não aparece no Terraform e não pode ser removida.

## 2. Associações

| Subnet | CIDR | Route table associada |
|---|---|---|
| subnet-publica | 10.0.1.0/24 | rt-publica |
| subnet-privada | 10.0.2.0/24 | rt-privada |

## 3. rt-publica

| Destino | Alvo | Origem da rota | Motivo |
|---|---|---|---|
| 10.0.0.0/16 | local | Automática | Comunicação interna entre as subnets da VPC |
| 0.0.0.0/0 | igw-corporativa (Internet Gateway) | Terraform (`aws_route_table.publica`) | Saída e entrada de tráfego da internet |

## 4. rt-privada

| Destino | Alvo | Origem da rota | Motivo |
|---|---|---|---|
| 10.0.0.0/16 | local | Automática | Comunicação interna entre as subnets da VPC |

Não há rota `0.0.0.0/0`. É isso que torna a subnet **privada**: nada nela tem caminho para a internet, e a internet não tem caminho até ela. Para dar saída (somente saída) a esses recursos no futuro, seria necessário um NAT.

## 5. Como o roteador escolhe a rota

A VPC usa **longest prefix match**: vence a rota mais específica que contém o destino. Exemplo na rt-publica:

| Destino do pacote | Rota escolhida | Motivo |
|---|---|---|
| 10.0.2.15 | 10.0.0.0/16 → local | /16 é mais específica que /0 |
| 8.8.8.8 | 0.0.0.0/0 → IGW | Só a rota padrão contém esse destino |

## 6. Exemplos de caminho

| Origem | Destino | Resultado | Motivo |
|---|---|---|---|
| Recurso em 10.0.1.x | Recurso em 10.0.2.x | Roteado | Rota local (ainda sujeito às regras de Security Group) |
| Recurso em 10.0.2.x | Recurso em 10.0.1.x | Roteado | Rota local |
| Recurso em 10.0.1.x | Internet | Roteado pelo IGW | Rota 0.0.0.0/0 (precisa de IP público ou Elastic IP) |
| Recurso em 10.0.2.x | Internet | Sem rota | Não existe 0.0.0.0/0 na rt-privada |
| Internet | Recurso em 10.0.2.x | Sem rota | A subnet privada não tem IP público nem rota para o IGW |

Observação: `map_public_ip_on_launch = false` na subnet pública significa que as instâncias lançadas ali **não** recebem IP público automaticamente. Para acessar a internet por essa subnet é preciso associar um Elastic IP ou ativar esse parâmetro.

## 7. Route table principal (main)

A VPC também possui uma route table principal criada automaticamente, só com a rota local. Como as duas subnets têm associação explícita, ela não é usada por nenhuma delas. Qualquer subnet nova sem associação cairia nela e ficaria sem saída para a internet.

## 8. Como conferir

```bash
terraform fmt -check
terraform validate
```

A conferência completa das rotas criadas (`plan`/`apply`) será feita no LocalStack, na próxima etapa do roadmap.
