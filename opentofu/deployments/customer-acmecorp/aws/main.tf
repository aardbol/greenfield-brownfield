module "vpc" {
  source = "../../../modules/aws/vpc"

  name       = "${var.customer_name}-vpc"
  cidr_block = var.vpc_cidr_block
  azs        = var.azs

  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  tags = var.tags
}

module "k8s" {
  source = "../../../modules/aws/kubernetes"

  name       = "${var.customer_name}-cluster"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  region     = var.region

  tags = var.tags
}
