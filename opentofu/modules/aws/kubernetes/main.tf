locals {
  create_cluster = var.existing_cluster_name == null
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = local.version_eks_module

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Endpoint access — public by default, can toggle
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_cidrs
  enabled_log_types            = var.cluster_log_types

  # IAM — make the caller admin automatically
  enable_cluster_creator_admin_permissions = var.cluster_creator_admin_permissions

  # EKS Auto Mode — AWS handles all compute; no managed node groups
  create_auto_mode_iam_resources = true
  compute_config = {
    enabled    = true
    node_pools = var.node_pools
  }

  tags = var.tags

  lifecycle {
    enabled = local.create_cluster
  }
}

# ── Data sources for existing cluster (brownfield)

data "aws_eks_cluster" "existing" {
  count = local.create_cluster ? 0 : 1
  name  = var.existing_cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  count = local.create_cluster ? 0 : 1
  name  = var.existing_cluster_name
}
