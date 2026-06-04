terraform {
  required_version = ">= 1.11"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

locals {
  version_network_module      = "~> 18.0"
  version_cloud_router_module = "~> 9.0"
}