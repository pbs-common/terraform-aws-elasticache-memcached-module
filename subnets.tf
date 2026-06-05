resource "aws_elasticache_subnet_group" "subnet_group" {
  count = var.subnet_group_name == null ? 1 : 0

  name       = local.name
  subnet_ids = local.subnets
}