resource "terraform_data" "validate_brownfield" {
  lifecycle {
    precondition {
      condition     = var.existing_cluster_name == null || (var.vpc_id != null && length(var.subnet_ids) > 0)
      error_message = "vpc_id and subnet_ids are still required when using an existing cluster (for the cluster data source)."
    }

    precondition {
      condition     = var.existing_cluster_name == null || length(var.node_pools) == 0
      error_message = "node_pools cannot be specified when using an existing cluster (brownfield mode)."
    }

    precondition {
      condition     = var.existing_cluster_name != null || var.vpc_id != null
      error_message = "vpc_id is required when creating a new cluster."
    }

    precondition {
      condition     = var.existing_cluster_name != null || length(var.subnet_ids) > 0
      error_message = "subnet_ids is required when creating a new cluster."
    }

    precondition {
      condition     = !var.endpoint_public_access || length(var.endpoint_public_cidrs) > 0
      error_message = "When public endpoint access is enabled, at least one CIDR must be provided in cluster_endpoint_public_cidrs."
    }
  }
}