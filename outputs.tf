output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "cidr_block" {
  description = "Bloco CIDR da VPC"
  value       = aws_vpc.main.cidr_block
}

output "azs" {
  description = "Lista com as AZs utilizadas no provisionamento das subnets"
  value       = local.azs
}

output "default_security_group_id" {
  description = "ID do security group default da VPC"
  value       = element(coalescelist(aws_security_group.default.*.id, tolist([""])), 0)
}

output "private_subnet_ids" {
  description = "Lista com os IDs das subnets privadas da VPC"
  value       = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  description = "Lista com os IDs das subnets públicas da VPC"
  value       = aws_subnet.public.*.id
}

output "private_route_table_id" {
  description = "ID da route table privada da VPC"
  value       = element(coalescelist(aws_route_table.private.*.id, tolist([""])), 0)
}

output "public_route_table_id" {
  description = "ID da route table pública da VPC"
  value       = element(coalescelist(aws_route_table.public.*.id, tolist([""])), 0)
}

output "nat_gateway_id" {
  description = "ID do NAT Gateway da VPC"
  value       = element(coalescelist(aws_nat_gateway.main.*.id, tolist([""])), 0)
}

output "nat_gateway_subnet_id" {
  description = "ID da subnet na qual o NAT Gateway está provisionado"
  value       = element(coalescelist(aws_nat_gateway.main.*.subnet_id, tolist([""])), 0)
}