locals {
  create_vpc = var.existing_network_name == null

  # Normalize subnets with defaults and ipv6 stack type
  subnets = [
    for s in var.subnets : merge(s, {
      stack_type                   = var.enable_ipv6 ? coalesce(s.stack_type, "IPV4_IPV6") : coalesce(s.stack_type, "IPV4_ONLY")
      subnet_flow_logs             = coalesce(s.subnet_flow_logs, var.enable_flow_log)
      subnet_flow_logs_interval    = coalesce(s.subnet_flow_logs_interval, var.flow_log_interval)
      subnet_flow_logs_sampling    = coalesce(s.subnet_flow_logs_sampling, var.flow_log_sampling_rate)
      subnet_flow_logs_metadata    = coalesce(s.subnet_flow_logs_metadata, var.flow_log_metadata)
      subnet_flow_logs_filter_expr = coalesce(s.subnet_flow_logs_filter_expr, var.flow_log_filter_expr)
    })
  ]

  # Identify private subnets for Cloud NAT routing
  private_subnet_names = [for s in local.subnets : s.subnet_name if s.subnet_private_access]
  nat_subnet_names     = length(var.cloud_nat_subnets) > 0 ? var.cloud_nat_subnets : local.private_subnet_names
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = local.version_network_module

  project_id   = var.project_id
  network_name = var.name
  routing_mode = "REGIONAL"

  subnets          = local.subnets
  secondary_ranges = var.secondary_ranges

  lifecycle {
    enabled = local.create_vpc
  }
}

# ── Cloud NAT (HA: Regional Cloud Router + manual NAT IPs)

# Reserve static regional IPs for predictable egress and whitelisting
resource "google_compute_address" "nat" {
  count = local.create_vpc && var.enable_cloud_nat ? var.cloud_nat_static_ips : 0

  name         = "${var.name}-nat-ip-${count.index + 1}"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  labels = var.labels

  lifecycle {
    prevent_destroy = true # survives NAT deletion
  }
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = local.version_cloud_router_module

  name       = "${var.name}-router"
  project_id = var.project_id
  network    = module.vpc.network_name
  region     = var.region

  nats = [{
    name    = "${var.name}-nat"
    nat_ips = var.cloud_nat_ip_allocate_option == "MANUAL_ONLY" ? google_compute_address.nat[*].self_link : []

    min_ports_per_vm                    = var.cloud_nat_min_ports_per_vm
    max_ports_per_vm                    = var.enable_dynamic_port_allocation ? var.cloud_nat_max_ports_per_vm : null
    enable_dynamic_port_allocation      = var.enable_dynamic_port_allocation
    enable_endpoint_independent_mapping = false

    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetworks = [
      for name in local.nat_subnet_names : {
        name                    = module.vpc.subnets_self_links[name]
        source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
      }
    ]

    log_config = {
      enable = var.cloud_nat_log_type != "DISABLED"
      filter = var.cloud_nat_log_type != "DISABLED" ? var.cloud_nat_log_type : "ERRORS_ONLY"
    }
  }]

  lifecycle {
    enabled = local.create_vpc && var.enable_cloud_nat
  }
}

# ── Data sources for existing network (brownfield)

data "google_compute_network" "existing" {
  count = local.create_vpc ? 0 : 1
  name  = var.existing_network_name
}

data "google_compute_subnetwork" "existing_private" {
  count   = local.create_vpc || var.auto_discover_existing_subnets ? 0 : length(var.existing_private_subnet_names)
  project = var.project_id
  name    = var.existing_private_subnet_names[count.index]
  region  = var.region
}

data "google_compute_subnetwork" "existing_public" {
  count   = local.create_vpc || var.auto_discover_existing_subnets ? 0 : length(var.existing_public_subnet_names)
  project = var.project_id
  name    = var.existing_public_subnet_names[count.index]
  region  = var.region
}

data "google_compute_subnetworks" "existing_private" {
  count   = local.create_vpc || !var.auto_discover_existing_subnets ? 0 : 1
  project = var.project_id
  region  = var.region
  filter  = "network:${var.existing_network_name} privateIpGoogleAccess:true"
}

data "google_compute_subnetworks" "existing_public" {
  count   = local.create_vpc || !var.auto_discover_existing_subnets ? 0 : 1
  project = var.project_id
  region  = var.region
  filter  = "network:${var.existing_network_name} privateIpGoogleAccess:false"
}

# ── Flow Logs

resource "google_logging_project_bucket_config" "flow_log" {
  project        = var.project_id
  location       = var.region
  bucket_id      = "${var.name}-vpc-flow-logs"
  retention_days = var.flow_log_retention_days

  lifecycle {
    enabled = var.enable_flow_log
  }
}

resource "google_logging_project_sink" "flow_log" {
  project     = var.project_id
  name        = "${var.name}-vpc-flow-logs"
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.region}/buckets/${google_logging_project_bucket_config.flow_log.bucket_id}"
  filter      = var.flow_log_filter_expr

  unique_writer_identity = true

  lifecycle {
    enabled = var.enable_flow_log
  }
}

resource "google_project_iam_member" "flow_log_writer" {
  project = var.project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_project_sink.flow_log.writer_identity

  lifecycle {
    enabled = var.enable_flow_log
  }
}