variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "europe-west1"
}

variable "customer_name" {
  type        = string
  description = "Customer name used as resource prefix"
}

# ── Brownfield VPC

variable "existing_network_name" {
  type        = string
  description = "Existing VPC network name"
}

variable "existing_private_subnet_names" {
  type        = list(string)
  default     = []
  description = "Existing private subnet names"
}

variable "existing_public_subnet_names" {
  type        = list(string)
  default     = []
  description = "Existing public subnet names"
}

# ── GKE

variable "gke_release_channel" {
  type        = string
  default     = "STABLE"
  description = "GKE release channel"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.gke_release_channel)
    error_message = "Must be one of: UNSPECIFIED, RAPID, REGULAR, STABLE."
  }
}

variable "gke_kubernetes_version" {
  type        = string
  default     = "latest"
  description = "Kubernetes version for the cluster"
}

variable "gke_private_nodes" {
  type        = bool
  default     = true
  description = "Use private GKE nodes (requires Cloud NAT on existing VPC)."
}

variable "ip_range_pods_name" {
  type        = string
  default     = null
  description = "Name of the secondary IP range for pods on the existing subnet. null = GKE auto-allocates."
}

variable "ip_range_services_name" {
  type        = string
  default     = null
  description = "Name of the secondary IP range for services on the existing subnet. null = GKE auto-allocates."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}
