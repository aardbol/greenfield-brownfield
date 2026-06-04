resource "terraform_data" "validate_brownfield" {
  lifecycle {
    precondition {
      condition     = var.existing_cluster_name == null || (var.existing_cluster_location != null)
      error_message = "existing_cluster_location is required when existing_cluster_name is set."
    }

    precondition {
      condition     = var.existing_cluster_name == null || !var.enable_private_nodes || var.enable_private_endpoint == false
      error_message = "Private nodes with public API (enable_private_endpoint=false) cannot be validated for existing clusters. Set enable_private_endpoint=true or use greenfield deployment."
    }
  }
}

resource "terraform_data" "validate_private_cluster" {
  lifecycle {
    precondition {
      condition     = !var.enable_private_nodes || var.master_ipv4_cidr_block != null
      error_message = "master_ipv4_cidr_block is required when enable_private_nodes is true."
    }

    precondition {
      condition     = !var.enable_private_endpoint || var.enable_private_nodes
      error_message = "enable_private_endpoint can only be true when enable_private_nodes is also true."
    }

    precondition {
      condition     = !var.enable_private_nodes || length(var.master_authorized_networks) > 0 || var.enable_private_endpoint
      error_message = "master_authorized_networks must be configured when using private nodes with public API endpoint."
    }
  }
}
