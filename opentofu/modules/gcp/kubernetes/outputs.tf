locals {
  kubeconfig_cmd_create   = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${module.gke.location} --project ${var.project_id}"
  kubeconfig_cmd_existing = "gcloud container clusters get-credentials ${var.existing_cluster_name} --region ${var.existing_cluster_location} --project ${var.project_id}"
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = local.create_cluster ? module.gke.cluster_name : var.existing_cluster_name
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint URL (marked sensitive)"
  sensitive   = true
  value       = local.create_cluster ? module.gke.endpoint : data.google_container_cluster.existing[0].endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded, marked sensitive)"
  sensitive   = true
  value       = local.create_cluster ? module.gke.ca_certificate : data.google_container_cluster.existing[0].master_auth[0].cluster_ca_certificate
}

output "cluster_location" {
  description = "Cluster location (region or zone)"
  value       = local.create_cluster ? module.gke.location : var.existing_cluster_location
}

output "cluster_region" {
  description = "Cluster region"
  value       = local.create_cluster ? var.region : var.existing_cluster_location
}

output "master_version" {
  description = "Current master Kubernetes version"
  value       = local.create_cluster ? module.gke.master_version : data.google_container_cluster.existing[0].master_version
}

output "configure_kubectl" {
  description = "Command to configure kubectl for this cluster"
  value       = local.create_cluster ? local.kubeconfig_cmd_create : local.kubeconfig_cmd_existing
}
