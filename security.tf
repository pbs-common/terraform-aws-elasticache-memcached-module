resource "aws_security_group" "sg" {
  count = var.security_group_ids == null ? 1 : 0

  description = "Controls access to the ${local.name} ${local.engine} cluster"

  name        = local.sg_name
  name_prefix = local.sg_name_prefix
  vpc_id      = local.vpc_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = var.security_group_ids == null && var.ingress_source_sg_id == null ? toset(var.ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.sg[0].id
  ip_protocol       = "tcp"
  from_port         = var.port
  to_port           = var.port
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "sg" {
  count = var.security_group_ids == null && var.ingress_source_sg_id != null ? 1 : 0

  security_group_id            = aws_security_group.sg[0].id
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port
  referenced_security_group_id = var.ingress_source_sg_id

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  count = var.security_group_ids == null && var.allow_all_egress ? 1 : 0

  security_group_id = aws_security_group.sg[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.tags
}