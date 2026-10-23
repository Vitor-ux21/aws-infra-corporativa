output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.corporativa.id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.publica.id
}

output "private_subnet_id" {
  description = "ID da subnet privada"
  value       = aws_subnet.privada.id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  description = "ID da route table pública"
  value       = aws_route_table.publica.id
}

output "private_route_table_id" {
  description = "ID da route table privada"
  value       = aws_route_table.privada.id
}

output "web_security_group_id" {
  description = "ID do Security Group web"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID do Security Group do servidor interno"
  value       = aws_security_group.app.id
}

output "private_nacl_id" {
  description = "ID da NACL da subnet privada"
  value       = aws_network_acl.privada.id
}
