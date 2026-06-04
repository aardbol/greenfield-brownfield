variable "name" {
  type        = string
  description = "Name prefix for all VPC resources"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.name))
    error_message = "The name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region (e.g., us-central1)"
}

variable "subnets" {
  type = list(object({
    subnet_name                  = string
    subnet_ip                    = string
    subnet_region                = optional(string)
    subnet_private_access        = optional(bool, true)
    subnet_private_ipv6_access   = optional(string)
    subnet_flow_logs             = optional(bool, false)
    subnet_flow_logs_interval    = optional(string, "INTERVAL_5_SEC")
    subnet_flow_logs_sampling    = optional(number, 0.5)
    subnet_flow_logs_metadata    = optional(string, "INCLUDE_ALL_METADATA")
    subnet_flow_logs_filter_expr = optional(string)
    description                  = optional(string)
    purpose                      = optional(string)
    role                         = optional(string)
    stack_type                   = optional(string)
    ipv6_access_type             = optional(string)
  }))
  description = "List of subnets to create in the VPC"

  default = [
    {
      subnet_name           = "default-private"
      subnet_ip             = "10.0.0.0/20"
      subnet_private_access = true
    },
  ]

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrhost(s.subnet_ip, 0))])
    error_message = "Each subnet_ip must be a valid CIDR notation."
  }
}

variable "secondary_ranges" {
  type = map(list(object({
    range_name    = string
    ip_cidr_range = optional(string)
  })))
  default     = {}
  description = "Secondary IP ranges for subnets (used by GKE for pods/services)"

  validation {
    condition     = alltrue([for ranges in var.secondary_ranges : alltrue([for r in ranges : can(cidrhost(r.ip_cidr_range, 0))])])
    error_message = "Each secondary range ip_cidr_range must be valid CIDR notation."
  }
}

variable "enable_ipv6" {
  type        = bool
  default     = false
  description = "Whether to enable IPv6 on the VPC subnets"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}

# ── Cloud NAT

variable "enable_cloud_nat" {
  type        = bool
  default     = true
  description = "Whether to create a Cloud Router + Cloud NAT for private subnet egress"
}

variable "cloud_nat_subnets" {
  type        = list(string)
  default     = []
  description = "Subnet names to NAT. Empty = all private subnets."
}

variable "cloud_nat_min_ports_per_vm" {
  type        = number
  default     = 64
  description = "Minimum ports allocated per VM"
}

variable "cloud_nat_max_ports_per_vm" {
  type        = number
  default     = 65536
  description = "Maximum ports per VM. Must be >= 256 if dynamic port allocation is enabled."
}

variable "enable_dynamic_port_allocation" {
  type        = bool
  default     = true
  description = "Enable dynamic port scaling from min to max"
}

variable "cloud_nat_ip_allocate_option" {
  type        = string
  default     = "MANUAL_ONLY"
  description = "MANUAL_ONLY (static IPs for whitelisting) or AUTO_ONLY"

  validation {
    condition     = contains(["MANUAL_ONLY", "AUTO_ONLY"], var.cloud_nat_ip_allocate_option)
    error_message = "Must be MANUAL_ONLY or AUTO_ONLY."
  }
}

variable "cloud_nat_static_ips" {
  type        = number
  default     = 2
  description = "Number of static regional IPs to reserve. Must be >= 1 for MANUAL_ONLY."

  validation {
    condition     = var.cloud_nat_ip_allocate_option != "MANUAL_ONLY" || var.cloud_nat_static_ips >= 1
    error_message = "cloud_nat_static_ips must be >= 1 when using MANUAL_ONLY."
  }
}

variable "cloud_nat_log_type" {
  type        = string
  default     = "ERRORS_ONLY"
  description = "NAT logging: ERRORS_ONLY, ALL, or DISABLED"

  validation {
    condition     = contains(["ERRORS_ONLY", "ALL", "DISABLED"], var.cloud_nat_log_type)
    error_message = "Must be ERRORS_ONLY, ALL, or DISABLED."
  }
}

# ── Flow Logs

variable "enable_flow_log" {
  type        = bool
  default     = false
  description = "Enable VPC Flow Log to Cloud Logging"
}

variable "flow_log_metadata" {
  type        = string
  default     = "INCLUDE_ALL_METADATA"
  description = "Metadata inclusion for flow logs"

  validation {
    condition     = contains(["INCLUDE_ALL_METADATA", "EXCLUDE_ALL_METADATA", "CUSTOM_METADATA"], var.flow_log_metadata)
    error_message = "Must be INCLUDE_ALL_METADATA, EXCLUDE_ALL_METADATA, or CUSTOM_METADATA."
  }
}

variable "flow_log_sampling_rate" {
  type        = number
  default     = 0.5
  description = "Flow log sampling rate (0.0 - 1.0)"

  validation {
    condition     = var.flow_log_sampling_rate >= 0.0 && var.flow_log_sampling_rate <= 1.0
    error_message = "Must be between 0.0 and 1.0."
  }
}

variable "flow_log_interval" {
  type        = string
  default     = "INTERVAL_5_SEC"
  description = "Flow log aggregation interval"
}

variable "flow_log_filter_expr" {
  type        = string
  default     = "status!=ACCEPT"
  description = "Optional Cloud Logging filter expression for flow logs. Default is to log only rejected traffic."
}

variable "flow_log_retention_days" {
  type        = number
  default     = 7
  description = "Flow log bucket retention in days"
}

# ── Brownfield

variable "existing_network_name" {
  type        = string
  default     = null
  description = "Existing VPC network name. When set, no new VPC is created."
}

variable "existing_private_subnet_names" {
  type        = list(string)
  default     = []
  description = "Existing private subnet names when using an existing network"
}

variable "existing_public_subnet_names" {
  type        = list(string)
  default     = []
  description = "Existing public subnet names when using an existing network"
}

variable "auto_discover_existing_subnets" {
  type        = bool
  default     = false
  description = "Auto-discover subnets from the existing VPC by private_ip_google_access"
}