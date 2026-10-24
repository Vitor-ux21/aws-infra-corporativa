# 04 - Matriz de conectividade

Fonte: `terraform/main.tf` e `terraform/security.tf`.

## 1. Premissas

O desenho considera os dois servidores futuros do projeto:

| Nome | Subnet | Security Group | Observação |
|---|---|---|---|
| web | 10.0.1.0/24 (pública) | sg-web | Precisa de Elastic IP para ser alcançado da internet |
| app | 10.0.2.0/24 (privada) | sg-app | Sem IP público |

Cada camada de controle atua em um nível diferente:

| Camada | Onde atua | Comportamento |
|---|---|---|
| Route table | Subnet | Define se existe caminho até o destino |
| NACL | Subnet | Stateless, com allow e deny; regras avaliadas em ordem; o que não casa é negado |
| Security Group | Instância | Stateful, somente allow; o que não tem regra é negado |

Um fluxo só funciona se houver rota e se as duas camadas de filtro permitirem. A subnet pública usa a NACL padrão da VPC (permite tudo), porque nenhuma NACL foi definida para ela.

## 2. Matriz resumida (origem x destino)

| Origem \ Destino | Internet | web (pública) | app (privada) |
|---|---|---|---|
| **Internet** | - | 80/tcp e 443/tcp | Bloqueado |
| **web** | 80/tcp e 443/tcp* | - | 8080/tcp |
| **app** | Bloqueado | Bloqueado | Bloqueado entre instâncias da mesma subnet |

\* Exige IP público (Elastic IP) na instância, porque a subnet pública não atribui IP automaticamente.

## 3. Matriz detalhada

| # | Origem | Destino | Porta/protocolo | Rota | NACL | Security Group | Resultado | Camada que decide |
|---|---|---|---|---|---|---|---|---|
| 1 | Internet | web | 80, 443/tcp | rt-publica: 0.0.0.0/0 pelo IGW | NACL padrão permite | sg-web permite | Permitido* | - |
| 2 | Internet | web | 22/tcp | Existe | NACL padrão permite | sg-web sem regra para 22 | Bloqueado | Security Group |
| 3 | Internet | app | Qualquer | Sem caminho: sem IP público e rt-privada sem rota para o IGW | Sem regra de entrada da internet | sg-app só aceita sg-web | Bloqueado | Rota |
| 4 | web | Internet | 80, 443/tcp | rt-publica: 0.0.0.0/0 pelo IGW | NACL padrão permite | Saída do sg-web permite 80 e 443 | Permitido* | - |
| 5 | web | app | 8080/tcp | Rota local | Regra 100 da NACL privada permite (origem 10.0.1.0/24); resposta liberada pela regra de saída 100 | sg-app permite (origem sg-web) | Permitido | - |
| 6 | web | app | 22/tcp ou outra porta | Rota local | Sem regra de entrada, cai no deny | sg-app sem regra | Bloqueado | NACL e Security Group |
| 7 | app | web | 80, 443/tcp | Rota local | Saída da NACL privada só libera 1024-65535 para 10.0.1.0/24 | Saída do sg-app permite a VPC | Bloqueado | NACL |
| 8 | app | Internet | Qualquer | rt-privada sem rota 0.0.0.0/0 | Sem regra de saída | Saída do sg-app só para a VPC | Bloqueado | Rota |
| 9 | app | DNS da VPC (10.0.2.2) | 53/udp | Dentro da VPC | A NACL não filtra o DNS da VPC | Saída do sg-app cobre 10.0.0.0/16 | Permitido | - |
| 10 | app | app (mesma subnet) | Qualquer | Rota local | A NACL não avalia tráfego dentro da subnet | sg-app não tem regra com origem nele mesmo | Bloqueado | Security Group |
| 11 | web | Internet | 22/tcp ou outras portas | Rota existe | NACL padrão permite | Saída do sg-web só permite 80, 443 e a porta da aplicação | Bloqueado | Security Group |

## 4. Como ler os casos mais didáticos

- **Caso 5 (resposta da aplicação):** o Security Group é stateful e devolve a resposta sozinho. A NACL é stateless, então a regra de saída 100 (portas 1024-65535 para a subnet pública) existe só para a resposta poder voltar.
- **Caso 7 (app chamando o web):** o Security Group de saída permite, mas a NACL bloqueia. Mostra que o fluxo precisa passar nas duas camadas.
- **Caso 3 (internet para app):** é bloqueado já na rota. Mesmo que um SG liberasse, não existe caminho.
- **Caso 10:** instâncias da mesma subnet privada não se falam, porque o sg-app só aceita origem sg-web. Se isso for necessário no futuro, uma regra com `self = true` resolve.

## 5. Lacunas conhecidas (próximas melhorias)

- [ ] A subnet pública usa a NACL padrão (permite tudo). Criar uma `nacl-publica` com regras explícitas.
- [x] Saída do sg-web restrita a 80, 443 e à porta da aplicação (resolvido na análise do Checkov).
- [ ] Apenas uma zona de disponibilidade.
- [ ] VPC Flow Logs para confirmar na prática o que foi aceito e rejeitado.
- [ ] Validar os casos desta matriz com testes reais (ping, curl, nmap) no laboratório.
