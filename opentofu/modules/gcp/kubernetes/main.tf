locals {
  create_cluster = var.existing_cluster_name == null
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/gke-autopilot-cluster"
  version = local.version_kubernetes_engine_module

  project_id = var.project_id
  name       = var.name
  location   = var.region

  network    = var.network
  subnetwork = var.subnetwork

  # IP allocation policy for VPC-native clusters
  ip_allocation_policy = {
    cluster_secondary_range_name  = var.ip_range_pods_name
    services_secondary_range_name = var.ip_range_services_name
  }

  release_channel = {
    channel = var.release_channel
  }

  min_master_version = var.kubernetes_version == "latest" ? null : var.kubernetes_version

  private_cluster_config = {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.enable_private_nodes ? var.master_ipv4_cidr_block : null
    master_global_access_config = {
      enabled = true
    }
  }

  # Master authorized networks - required input
  master_authorized_networks_config = var.enable_private_nodes ? {
    cidr_blocks                     = var.master_authorized_networks
    gcp_public_cidrs_access_enabled = var.enable_private_endpoint ? false : true
    } : {
    cidr_blocks                     = []
    gcp_public_cidrs_access_enabled = true
  }

  # Workload Identity - required input
  workload_identity_config = var.enable_workload_identity ? {
    workload_pool = "${var.project_id}.svc.id.goog"
  } : null

  maintenance_policy = {
    recurring_window = {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }

  logging_config = length(var.logging_components) > 0 ? {
    enable_components = var.logging_components
  } : null

  monitoring_config = length(var.monitoring_components) > 0 ? {
    enable_components = var.monitoring_components
  } : null

  resource_labels = var.tags

  deletion_protection = var.deletion_protection

  lifecycle {
    enabled = local.create_cluster
  }
}

# ── Data sources for existing cluster (brownfield)

data "google_container_cluster" "existing" {
  count = local.create_cluster ? 0 : 1

  project  = var.project_id
  name     = var.existing_cluster_name
  location = var.existing_cluster_location
}
