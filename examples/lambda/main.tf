module "lambda" {
  source = "github.com/pbs/terraform-aws-lambda-module?ref=2.0.0"

  handler  = "index.handler"
  filename = "./artifacts/handler.zip"
  runtime  = "python3.9"

  architectures = ["arm64"]

  add_vpc_config = true

  environment_vars = {
    "MEMCACHED_CLUSTER_ADDRESS" = module.memcached.cluster_address
  }

  organization = var.organization
  environment  = var.environment
  product      = var.product
  repo         = var.repo
  owner        = var.owner
}

module "memcached" {
  source = "../.."

  organization = var.organization
  environment  = var.environment
  product      = var.product
  repo         = var.repo
  owner        = var.owner
}

resource "aws_security_group_rule" "memcached_ingress_rule" {
  type                     = "ingress"
  from_port                = 11211
  to_port                  = 11211
  protocol                 = "tcp"
  source_security_group_id = module.lambda.sg
  security_group_id        = module.memcached.sg_ids[0]
}
