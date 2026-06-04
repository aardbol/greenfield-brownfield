resource "terraform_data" "validate_brownfield" {
  lifecycle {
    precondition {
      condition     = var.existing_vpc_id == null || length(var.existing_private_subnet_ids) > 0 || var.auto_discover_existing_subnets
      error_message = "When using an existing VPC (existing_vpc_id) you must either provide existing_private_subnet_ids or set auto_discover_existing_subnets=true."
    }

    precondition {
      condition     = var.existing_vpc_id == null || length(var.existing_public_subnet_ids) > 0 || var.auto_discover_existing_subnets
      error_message = "When using an existing VPC (existing_vpc_id) you must either provide existing_public_subnet_ids or set auto_discover_existing_subnets=true."
    }

    precondition {
      condition     = var.existing_vpc_id != null || length(var.private_subnet_cidrs) == length(var.public_subnet_cidrs)
      error_message = "When creating a new VPC, the number of private_subnet_cidrs must equal the number of public_subnet_cidrs."
    }

    precondition {
      condition     = var.existing_vpc_id != null || length(var.azs) == 0 || length(var.azs) == length(var.private_subnet_cidrs)
      error_message = "When creating a new VPC with explicit azs, the number of azs must equal the number of private_subnet_cidrs."
    }
  }
}