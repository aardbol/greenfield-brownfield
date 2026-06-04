# ── Data sources for existing VPC (brownfield)

data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

data "aws_subnets" "existing_private" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_subnets" "existing_public" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

# ── EKS cluster (greenfield — k8s needs installing in existing VPC)

module "k8s" {
  source = "../../../modules/aws/kubernetes"

  name       = "${var.customer_name}-cluster"
  vpc_id     = var.existing_vpc_id
  subnet_ids = length(var.existing_private_subnet_ids) > 0 ? var.existing_private_subnet_ids : data.aws_subnets.existing_private.ids
  region     = var.region

  kubernetes_version                = var.eks_kubernetes_version
  endpoint_public_access            = var.cluster_endpoint_public_access
  node_pools                        = var.node_pools
  cluster_creator_admin_permissions = true

  # NOTE: existing_cluster_name is NOT set — this creates a NEW cluster
  # inside the existing VPC (brownfield VPC, greenfield k8s)

  tags = var.tags
}
