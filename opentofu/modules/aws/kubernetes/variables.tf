variable "name" {
  type        = string
  description = "EKS cluster name"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]*$", var.name))
    error_message = "The name must start with alphanumeric and contain only alphanumeric, hyphens, and underscores."
  }
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region (e.g., us-west-2)"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "The region must be a valid AWS region identifier (e.g., us-west-2, eu-central-1)."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy the cluster into"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the node group and control plane"

  validation {
    condition     = alltrue([for subnet_id in var.subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet_id))])
    error_message = "Each subnet ID must be a valid AWS subnet ID (e.g., subnet-12345678)."
  }
}

variable "kubernetes_version" {
  type        = string
  default     = "1.34"
  description = "Kubernetes version (e.g., '1.34')"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "The kubernetes_version must be a valid version string in the form 'MAJOR.MINOR' (e.g., '1.34')."
  }
}

variable "endpoint_public_access" {
  type        = bool
  default     = true
  description = "Whether the API endpoint is publicly accessible"
}

variable "endpoint_public_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access the public API endpoint"

  validation {
    condition     = alltrue([for cidr in var.endpoint_public_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each cluster_endpoint_public_cidrs element must be a valid CIDR notation."
  }
}

variable "cluster_log_types" {
  type        = list(string)
  default     = ["audit", "api", "authenticator"]
  description = "EKS cluster log types to enable. Defaults to audit, api, and authenticator."

  validation {
    condition     = alltrue([for log in var.cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log)])
    error_message = "Log types must be one or more of: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "node_pools" {
  type        = list(string)
  default     = ["general-purpose"]
  description = "EKS Auto Mode node pools to enable. AWS manages node lifecycle, scaling, and instance selection."

  validation {
    condition     = alltrue([for pool in var.node_pools : contains(["general-purpose", "system"], pool)])
    error_message = "Each node pool must be one of: general-purpose, system."
  }
}

variable "cluster_creator_admin_permissions" {
  type        = bool
  default     = true
  description = "Whether to automatically grant cluster creator admin permissions"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

# ── Brownfield

variable "existing_cluster_name" {
  type        = string
  default     = null
  description = "Existing EKS cluster name. When set, only outputs are surfaced."
}
