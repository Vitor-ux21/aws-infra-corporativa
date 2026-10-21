# Arquitetura da infraestrutura AWS

mermaid
flowchart TB
    Internet((Internet))

    subgraph AWS["AWS - us-east-1"]
        subgraph VPC["VPC corporativa - 10.0.0.0/16"]
            IGW["Internet Gateway"]
            PUB["Subnet pública<br/>10.0.1.0/24"]
            RPUB["Tabela de rotas pública<br/>0.0.0.0/0 → IGW"]
            PRIV["Subnet privada<br/>10.0.2.0/24"]
            RPRIV["Tabela de rotas privada"]
            SG["Security Group web<br/>HTTP 80 / HTTPS 443"]
            
            Internet --- IGW
            IGW --- RPUB
            RPUB --- PUB
            RPRIV --- PRIV
            SG -. protege futuro servidor web .-> PUB
        end
    end


## Observações

- A infraestrutura está definida em Terraform.
- O código ainda não foi implantado na AWS.
- A subnet pública possui rota para o Internet Gateway.
- A subnet privada não possui rota direta para a internet.
- O Security Group permite tráfego HTTP e HTTPS de entrada.
-
