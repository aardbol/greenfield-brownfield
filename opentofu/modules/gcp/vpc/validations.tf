resource "terraform_data" "validate_brownfield" {
  lifecycle {
    precondition {
      condition     = var.existing_network_name == null || length(var.existing_private_subnet_names) > 0 || var.auto_discover_existing_subnets
      error_message = "When using an existing network you must either provide existing_private_subnet_names or set auto_discover_existing_subnets=true."
    }

    precondition {
      condition     = var.existing_network_name == null || length(var.existing_public_subnet_names) > 0 || var.auto_discover_existing_subnets
      error_message = "When using an existing network you must either provide existing_public_subnet_names or set auto_discover_existing_subnets=true."
    }

    precondition {
      condition     = var.existing_network_name != null || length(var.subnets) > 0
      error_message = "When creating a new VPC, you must provide at least one subnet."
    }
  }
}

resource "terraform_data" "validate_cloud_nat" {
  lifecycle {
    precondition {
      condition     = !var.enable_cloud_nat || var.existing_network_name == null
      error_message = "Cloud NAT can only be created for new VPCs."
    }

    precondition {
      condition = !var.enable_cloud_nat || length(var.cloud_nat_subnets) == 0 || alltrue([
        for name in var.cloud_nat_subnets : contains([for s in var.subnets : s.subnet_name], name)
      ])
      error_message = "cloud_nat_subnets must reference names from the subnets variable."
    }

    precondition {
      condition     = !var.enable_cloud_nat || !var.enable_dynamic_port_allocation || var.cloud_nat_max_ports_per_vm >= 256
      error_message = "Dynamic port allocation requires cloud_nat_max_ports_per_vm >= 256."
    }
  }
}

resource "terraform_data" "validate_flow_logs" {
  lifecycle {
    precondition {
      condition     = !var.enable_flow_log || var.existing_network_name == null
      error_message = "VPC Flow Logs can only be configured for new VPCs."
    }
  }
}