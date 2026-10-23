# 01 - Plano de endereçamento

Projeto: aws-cloud-networking-lab (nome atual do repositório: aws-infra-corporativa)

## 1. Visão geral

Toda a rede do laboratório sai de um único bloco privado (RFC 1918), `10.0.0.0/16`, dividido em sub-redes `/24`. Os blocos de outras redes do projeto (segunda VPC e rede on-premises simulada) já ficam reservados em faixas diferentes para **nunca haver sobreposição de CIDR**, que é o requisito para peering, Transit Gateway e VPN.

## 2. Tabela de sub-redes (implementadas)

| Rede | CIDR | Máscara | Endereço de rede | Broadcast | Total de IPs | IPs utilizáveis na AWS | Função |
|---|---|---|---|---|---|---|---|
| VPC principal | 10.0.0.0/16 | 255.255.0.0 | 10.0.0.0 | 10.0.255.255 | 65.536 | - | Rede do laboratório |
| Subnet pública | 10.0.1.0/24 | 255.255.255.0 | 10.0.1.0 | 10.0.1.255 | 256 | 251 (10.0.1.4 a 10.0.1.254) | Recursos com rota para o Internet Gateway |
| Subnet privada | 10.0.2.0/24 | 255.255.255.0 | 10.0.2.0 | 10.0.2.255 | 256 | 251 (10.0.2.4 a 10.0.2.254) | Recursos internos, sem rota para a internet |

## 3. IPs reservados pela AWS em cada subnet

Em toda subnet a AWS reserva 5 endereços. Na `10.0.1.0/24`, por exemplo:

| Endereço | Uso |
|---|---|
| 10.0.1.0 | Endereço de rede |
| 10.0.1.1 | Roteador da VPC |
| 10.0.1.2 | Servidor DNS da VPC (base da rede + 2) |
| 10.0.1.3 | Reservado para uso futuro |
| 10.0.1.255 | Broadcast (reservado; a VPC não suporta broadcast) |

Por isso uma `/24` entrega 251 IPs, e não 254 como em uma LAN tradicional.

## 4. Blocos reservados para as próximas fases

| Rede | CIDR | Situação | Fase do roadmap |
|---|---|---|---|
| Segunda VPC | 10.1.0.0/16 | Reservado (ainda não criado) | 2. Peering |
| Rede on-premises simulada | 192.168.10.0/24 | Reservado (ainda não criado) | 3. Híbrido |
| Espaço livre dentro da VPC principal | 10.0.0.0/24 e 10.0.3.0/24 a 10.0.255.0/24 | Livre para crescimento | Várias |

Verificação de sobreposição: `10.0.0.0/16` x `10.1.0.0/16` = sem sobreposição; `10.0.0.0/16` x `192.168.10.0/24` = sem sobreposição.

## 5. Justificativa do dimensionamento

- **/16 na VPC:** maior bloco permitido na AWS para uma VPC. Dá espaço para crescer sem renumerar a rede, o que é caro e arriscado depois que há recursos em uso.
- **/24 nas subnets:** 251 hosts utilizáveis por subnet é suficiente para o laboratório, é fácil de ler (o terceiro octeto identifica a subnet) e deixa muitas sub-redes livres.
- **Terceiro octeto como identificador:** `10.0.1.x` = pública, `10.0.2.x` = privada. Quem lê um IP nos logs sabe de qual segmento ele veio.
- **Blocos diferentes por rede:** evita overlap em peering, Transit Gateway e VPN.

## 6. Como conferir os números

Qualquer pessoa pode validar a tabela com Python:

```bash
python3 -c "import ipaddress as i; n=i.ip_network('10.0.1.0/24'); print(n.netmask, n.broadcast_address, n.num_addresses)"
```

Saída esperada: `255.255.255.0 10.0.1.255 256`

## 7. Pendências

- [x] Conferir se os CIDRs do `terraform/` batem com esta tabela (variáveis em `variables.tf`).
- [ ] Atualizar este documento quando a segunda VPC e a rede on-premises forem criadas.
