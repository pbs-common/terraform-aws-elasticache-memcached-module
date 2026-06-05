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

  ingress_source_sg_id = module.lambda.sg
}
