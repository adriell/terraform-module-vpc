#AZ disponíveis
data "aws_availability_zones" "available"{
    state = "available"
}

# ----------------------------------------------------------------------------------------------------------------------
# Locals
# ----------------------------------------------------------------------------------------------------------------------

locals {
  # O join() é usado porque listas não podem ser usadas no operador ternário
  available_azs = length(var.azs) > 0 ? join(",", var.azs) : join(",", data.aws_availability_zones.available.names)

  # Lista (propriamente dita) das AZs disponíveis
  azs = split(",", local.available_azs)

  # Condicional de criação do NAT Gateway
  create_nat_gateway = var.enable_nat_gateway && length(var.public_subnets) > 0
}

# ----------------------------------------------------------------------------------------------------------------------
# VPC
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_vpc" "main" {
    cidr_block = var.cidr

    enable_dns_hostnames = var.enable_dns_hostnames
    enable_dns_support   = var.enable_dns_support
    instance_tenancy     = var.instance_tenancy

    tags = merge(map("Name","${var.name}-vpc"), var.tags)
}

# ----------------------------------------------------------------------------------------------------------------------
# Private Subnet
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "private" {
    count = length(var.private_subnets)

    vpc_id                  = aws_vpc.main.id
    cidr_block              = element(concat(var.private_subnets, list("")), count.index)
    availability_zone       = element(local.azs, count.index)
    map_public_ip_on_launch = false

      tags = merge(
          map("Name", "${var.name}-subnet-priv"),
          var.tags
      )   
}

# ----------------------------------------------------------------------------------------------------------------------
# Private Route Table
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_route_table" "private" {
    count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

    vpc_id = aws_vpc.main.id

    tags = merge(
        map("Name", "${var.name}-rt-priv"),
        var.tags
    )
}

resource "aws_route" "private_nat_gateway" {
    count = local.create_nat_gateway && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

    route_table_id          = element(aws_route_table.private.*.id, count.index)
    destination_cidr_block  = "0.0.0.0/0"
    nat_gateway_id          = element(aws_nat_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "private" {
    count = local.create_nat_gateway && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0
    
    subnet_id       = element(aws_subnet.private.*.id, count.index)
    route_table_id  = element(aws_route_table.private.*.id, count.index)
}

# ----------------------------------------------------------------------------------------------------------------------
# Public Subnet
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "public" {
    count = length(var.public_subnets)

    vpc_id                  = aws_vpc.main.id
    cidr_block              = element(concat(var.public_subnets, list("")), count.index)
    availability_zone       = element(local.azs, count.index)
    map_public_ip_on_launch = true

      tags = merge(
          map("Name", "${var.name}-subnet-publ"),
          var.tags
      )   
}

# ----------------------------------------------------------------------------------------------------------------------
# Private Route Table
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_route_table" "public" {
    count = length(var.public_subnets) > 0 ? 1 : 0

    vpc_id = aws_vpc.main.id

    tags = merge(
        map("Name", "${var.name}-rt-publ"),
        var.tags
    )
}

resource "aws_route" "public_default" {
    count = length(var.public_subnets) > 0 ? 1 : 0

    route_table_id          = element(aws_route_table.public.*.id, count.index)
    destination_cidr_block  = "0.0.0.0/0"
    gateway_id              = element(aws_internet_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "public" {
    count = length(var.public_subnets)
    
    subnet_id       = element(aws_subnet.public.*.id, count.index)
    route_table_id  = aws_route_table.public[0].id
}

# ----------------------------------------------------------------------------------------------------------------------
# Internet Gateway
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = merge(map("Name", "${var.name}-igw"), var.tags)
}

# ----------------------------------------------------------------------------------------------------------------------
# NAT Gateway + Elastic IP
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "nat_gateway" {
    count = local.create_nat_gateway ? length(var.public_subnets) : 0

    vpc        = true
    depends_on = [aws_internet_gateway.main]

    tags = merge(map("Name", "${var.name}-nat-gw"), var.tags)
}

resource "aws_nat_gateway" "main" {
    count = local.create_nat_gateway ? length(var.public_subnets) : 0

    allocation_id = element(aws_eip.nat_gateway.*.id, count.index)
    subnet_id     = element(aws_subnet.public.*.id, count.index)

    depends_on = [aws_internet_gateway.main, aws_subnet.public]

    tags = merge(map("Name", "${var.name}-nat-gw"), var.tags)
}

# ----------------------------------------------------------------------------------------------------------------------
# Default Security Group
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "default" {
    count = var.enable_default_security_group ? 1 : 0
    
    name        = "${var.name}-default-sg"
    description = var.default_security_group_description != "" ? var.default_security_group_description : "[TF] ${var.name} - Default Security Group"
    vpc_id      = aws_vpc.main.id

    tags = merge(map("Name", "${var.name}-default-sg"), var.tags)
}

resource "aws_security_group_rule" "ingress_allow_vpc" {
    count = var.enable_default_security_group ? 1 : 0

    security_group_id = element(aws_security_group.default.*.id, count.index)

    type        = "ingress"
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    self        = true
    description = "[TF] VPC self security group"
}

resource "aws_security_group_rule" "egress_allow_vpc" {
    count = var.enable_default_security_group ? 1 : 0

    security_group_id = element(aws_security_group.default.*.id, count.index)

    type        = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    self        = true
    description = "[TF] VPC self security group"
}

resource "aws_security_group_rule" "egress_allow_all" {
    count = var.enable_default_security_group && var.allow_all_egress ? 1 : 0

    security_group_id = element(aws_security_group.default.*.id, count.index)

    type        = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
    description = "[TF] Allow all egress"
}

