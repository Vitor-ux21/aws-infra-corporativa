# 05 - Análise de segurança com Checkov

Ferramenta: Checkov (análise estática de Terraform, sem credenciais e sem criar recursos).
Comando: `checkov -d terraform --framework terraform`

## 1. Primeira execução

Resultado: **22 verificações aprovadas e 6 reprovadas**.

## 2. Triagem dos achados

Cada achado recebeu uma decisão: corrigir, aceitar com justificativa ou adiar.

| Verificação | Recurso | Decisão | Justificativa |
|---|---|---|---|
| CKV_AWS_382: saída para 0.0.0.0/0 em todas as portas | sg-web | **Corrigido** | A saída foi restrita a 80 e 443 (internet) e à porta da aplicação, apenas para a subnet privada |
| CKV_AWS_260: entrada para 0.0.0.0/0 na porta 80 | sg-web | **Aceito** | Servidor web público; a porta 80 serve para redirecionar para HTTPS |
| CKV2_AWS_12: Security Group padrão da VPC deve bloquear todo o tráfego | VPC | **Corrigido** | Adicionado `aws_default_security_group` sem nenhuma regra |
| CKV2_AWS_11: VPC Flow Logs ativado | VPC | **Corrigido** | Flow Logs implementados com CloudWatch Logs (retencao de 365 dias) em `terraform/flow_logs.tf`. O custo so existe se houver `apply` |
| CKV_AWS_158: Log group criptografado com KMS | CloudWatch Log Group | **Exceção justificada** | Sem KMS no laboratorio para evitar custo e complexidade |
| CKV2_AWS_5: Security Group anexado a um recurso | sg-web e sg-app | **Aceito (temporário)** | Os servidores ainda não existem; serão criados em fase futura |

Os itens aceitos e adiados estão registrados no código com `#checkov:skip=<id>:<motivo>`, para que a decisão fique visível e auditável.

## 3. Resultado esperado após as correções

Zero reprovações, com 4 exceções documentadas no código. O Checkov roda no CI sem `--soft-fail`: qualquer falha nova reprova o pull request.

## 4. Observação sobre o DNS

Nem Security Groups nem NACLs filtram o tráfego para o DNS da VPC (Route 53 Resolver, base + 2). Por isso não há regras de DNS nas restrições de saída.
