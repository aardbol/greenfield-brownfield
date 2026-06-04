
output "network_name" {
  description = "VPC network name (created or existing)"
  value       = local.create_vpc ? module.vpc.network_name : var.existing_network_name
}

output "network_self_link" {
  description = "VPC network self-link (URI)"
  value       = local.create_vpc ? module.vpc.network_self_link : data.google_compute_network.existing[0].self_link
}

output "network_id" {
  description = "VPC network numeric ID"
  value       = local.create_vpc ? module.vpc.network_id : data.google_compute_network.existing[0].id
}

output "subnets_names" {
  description = "List of all subnetwork names"
  value = local.create_vpc ? module.vpc.subnets_names : (
    var.auto_discover_existing_subnets ? concat(
      try([for s in data.google_compute_subnetworks.existing_private[0].subnetworks : s.name], []),
      try([for s in data.google_compute_subnetworks.existing_public[0].subnetworks : s.name], [])
    ) : concat(data.google_compute_subnetwork.existing_private[*].name, data.google_compute_subnetwork.existing_public[*].name)
  )
}

output "subnets_self_links" {
  description = "Map of subnetwork names to their self-links"
  value = local.create_vpc ? module.vpc.subnets_self_links : merge(
    { for s in data.google_compute_subnetwork.existing_private : s.name => s.self_link },
    { for s in data.google_compute_subnetwork.existing_public : s.name => s.self_link }
  )
}

output "subnets_ips" {
  description = "Map of subnetwork names to their IP CIDR ranges"
  value = local.create_vpc ? module.vpc.subnets_ips : merge(
    { for s in data.google_compute_subnetwork.existing_private : s.name => s.ip_cidr_range },
    { for s in data.google_compute_subnetwork.existing_public : s.name => s.ip_cidr_range }
  )
}

output "private_subnet_names" {
  description = "Private subnet names (subnets with private_ip_google_access)"
  value = local.create_vpc ? [
    for s in var.subnets : s.subnet_name if s.subnet_private_access
    ] : (
    var.auto_discover_existing_subnets ? try(data.google_compute_subnetworks.existing_private[0].subnetworks, []) : [for s in data.google_compute_subnetwork.existing_private : s.name]
  )
}

output "public_subnet_names" {
  description = "Public subnet names (subnets without private_ip_google_access)"
  value = local.create_vpc ? [
    for s in var.subnets : s.subnet_name if !s.subnet_private_access
    ] : (
    var.auto_discover_existing_subnets ? try(data.google_compute_subnetworks.existing_public[0].subnetworks, []) : [for s in data.google_compute_subnetwork.existing_public : s.name]
  )
}

output "secondary_ranges" {
  description = "Map of subnet names to secondary IP ranges (for GKE pods/services)"
  value       = local.create_vpc ? module.vpc.subnets_secondary_ranges : {}
}

output "project_id" {
  description = "GCP project ID (pass-through)"
  value       = var.project_id
}

output "region" {
  description = "GCP region (pass-through)"
  value       = var.region
}

output "nat_ips" {
  description = "Static external IPs for Cloud NAT whitelisting"
  value       = local.create_vpc && var.enable_cloud_nat ? google_compute_address.nat[*].address : null
}

output "nat_ip_self_links" {
  description = "Self-links of NAT IPs"
  value       = local.create_vpc && var.enable_cloud_nat ? google_compute_address.nat[*].self_link : null
}

output "router_name" {
  description = "Cloud Router name"
  value       = local.create_vpc && var.enable_cloud_nat ? module.cloud_router.router.name : null
}

output "flow_log_bucket_id" {
  description = "Cloud Logging bucket for flow logs (null if disabled)"
  value       = var.enable_flow_log ? google_logging_project_bucket_config.flow_log.bucket_id : null
}

output "flow_log_sink_id" {
  description = "Cloud Logging sink for flow logs (null if disabled)"
  value       = var.enable_flow_log ? google_logging_project_sink.flow_log.id : null
}
