# AWS Corporate Infrastructure with Terraform

## Overview

Projeto de estudo de infraestrutura em nuvem utilizando Terraform e AWS,
com foco em redes, segmentação e segurança.

## Architecture

- VPC: 10.0.0.0/16
- Subnet pública: 10.0.1.0/24
- Subnet privada: 10.0.2.0/24
- Internet Gateway para conectividade da subnet pública
- Tabelas de rotas separadas
- Security Group com regras HTTP e HTTPS

## Technologies

- AWS
- Terraform
- AWS CLI
- Git

## Validation

A configuração foi validada localmente com:

bash
terraform fmt
terraform validate


## Current Status

A infraestrutura está definida como código e validada localmente.
Ainda não foi implantada na AWS.

## Cost and Security

Nenhum recurso foi criado na AWS neste projeto até o momento.
As regras de acesso e os custos deverão ser revisados antes de qualquer implantação
