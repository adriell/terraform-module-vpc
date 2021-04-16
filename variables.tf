variable "name" {
  description = "Nome da VPC"
  type        = string
}

variable "cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones onde as subnets serão criadas; caso vazia, serão usadas as AZs da região configurada"
  type        = list(any)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "Habilita hostnames DNS na VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Habilita suporte a DNS na VPC"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "Tipo de locação de instâncias criadas na VPC"
  type        = string
  default     = "default"
}

variable "enable_nat_gateway" {
  description = "Habilita criação de um NAT Gateway; requer ao menos uma subnet pública"
  type        = bool
  default     = true
}

variable "private_subnets" {
  description = "Lista de CIDRs das subnets privadas"
  type        = list(any)
  default     = []
}

variable "private_subnet_names" {
  description = "Lista de nomes das subnets privadas"
  type        = list(any)
  default     = []
}

variable "public_subnets" {
  description = "Lista de CIDRs das subnets públicas"
  type        = list(any)
  default     = []
}

variable "public_subnet_names" {
  description = "Lista de nomes das subnets públicas"
  type        = list(any)
  default     = []
}

variable "allow_all_egress" {
  description = "Habilita wildcard (`0.0.0.0/0`) como regra de saída do security group padrão"
  type        = bool
  default     = true
}

variable "allow_extra_cidr_blocks" {
  description = "Lista de CIDRs adicionais para liberação de entrada no security group da VPC; requer que `enable_default_security_group` seja habilitada"
  type        = list(any)
  default     = []
}

variable "allow_extra_cidr_blocks_egress" {
  description = "Lista de CIDRs adicionais para liberação de saída no security group da VPC; requer que `enable_default_security_group` seja habilitada"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Map de tags comuns a todos os recursos"
  type        = map(string)
  default     = {}
}

variable "enable_default_security_group" {
  description = "Habilita criação de um security group padrão para a VPC"
  type        = bool
  default     = true
}

variable "default_security_group_description" {
  description = "Descrição do security group default da VPC"
  type        = string
  default     = ""
}