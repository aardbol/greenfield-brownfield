variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "name" {
  type        = string
  description = "Cluster name"
}

variable "region" {
  type        = string
  description = "GCP region (e.g., us-central1)"
}

variable "network" {
  type        = string
  description = "VPC network name to deploy the cluster into"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork name to host the cluster nodes"
}

variable "ip_range_pods_name" {
  type        = string
  default     = null
  description = "Name of the secondary IP range for pods (null = GKE auto-allocates)"
}

variable "ip_range_services_name" {
  type        = string
  default     = null
  description = "Name of the secondary IP range for services (null = GKE auto-allocates)"
}

variable "kubernetes_version" {
  type        = string
  default     = "latest"
  description = "Kubernetes version. 'latest' uses the default from the release channel."
}

variable "release_channel" {
  type        = string
  default     = "STABLE"
  description = "GKE release channel: UNSPECIFIED, RAPID, REGULAR, or STABLE"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be one of: UNSPECIFIED, RAPID, REGULAR, STABLE."
  }
}

# ── Node privacy

variable "enable_private_nodes" {
  type        = bool
  default     = true
  description = "If true, nodes get internal IPs only (requires Cloud NAT for egress). Default: private nodes."
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "If true, the API endpoint is private (requires enable_private_nodes=true). Default: public API access."
}

variable "master_ipv4_cidr_block" {
  type        = string
  default     = "10.0.0.0/28"
  description = "CIDR block for the control plane VPC peering (only used when enable_private_nodes=true)"
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "public-access"
    }
  ]
  description = "CIDRs authorized to access the control plane. Defaults to 0.0.0.0/0 for public API access when enable_private_endpoint=false"
}

variable "enable_workload_identity" {
  type        = bool
  default     = true
  description = "Whether to enable Workload Identity for Kubernetes service accounts"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all cluster resources where supported"
}

variable "maintenance_start_time" {
  type        = string
  default     = "2024-01-01T03:00:00Z"
  description = "Maintenance window start time (RFC3339 format)"
}

variable "maintenance_end_time" {
  type        = string
  default     = "2024-01-01T05:00:00Z"
  description = "Maintenance window end time (RFC3339 format)"
}

variable "maintenance_recurrence" {
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SA,SU"
  description = "Maintenance window recurrence (RFC5545 RRULE format)"
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Whether Terraform will be prevented from destroying the cluster. Set to true in production."
}

# ── Observability

variable "logging_components" {
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  description = "GKE components exposing logs. Supported values: SYSTEM_COMPONENTS, APISERVER, CONTROLLER_MANAGER, SCHEDULER, WORKLOADS"

  validation {
    condition = alltrue([
      for c in var.logging_components : contains(["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER", "WORKLOADS"], c)
    ])
    error_message = "logging_components must contain only valid values: SYSTEM_COMPONENTS, APISERVER, CONTROLLER_MANAGER, SCHEDULER, WORKLOADS"
  }
}

variable "monitoring_components" {
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
  description = "GKE components exposing metrics. Supported values: SYSTEM_COMPONENTS, APISERVER, SCHEDULER, CONTROLLER_MANAGER, STORAGE, HPA, POD, DAEMONSET, DEPLOYMENT, STATEFULSET, KUBELET, CADVISOR, DCGM, JOBSET"

  validation {
    condition = alltrue([
      for c in var.monitoring_components : contains(
        ["SYSTEM_COMPONENTS", "APISERVER", "SCHEDULER", "CONTROLLER_MANAGER", "STORAGE", "HPA", "POD", "DAEMONSET", "DEPLOYMENT", "STATEFULSET", "KUBELET", "CADVISOR", "DCGM", "JOBSET"],
        c
      )
    ])
    error_message = "monitoring_components must contain only valid values"
  }
}

# ── Brownfield

variable "existing_cluster_name" {
  type        = string
  default     = null
  description = "Existing GKE cluster name. When set, no new cluster is created — outputs are surfaced."
}

variable "existing_cluster_location" {
  type        = string
  default     = null
  description = "Location (region or zone) of the existing cluster. Required when existing_cluster_name is set."
}
