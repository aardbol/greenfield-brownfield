variable "customer_name" {
  type        = string
  description = "Customer name used as resource prefix"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Must be a valid AWS region identifier (e.g., us-west-2, eu-central-1)."
  }
}

# ── Brownfield VPC

variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC ID to deploy the EKS cluster into"
}

variable "existing_private_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Existing private subnet IDs. Leave empty to auto-discover by EKS ELB tags."
}

# ── EKS

variable "eks_kubernetes_version" {
  type        = string
  default     = "1.34"
  description = "Kubernetes version for EKS"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.eks_kubernetes_version))
    error_message = "Must be in the form 'MAJOR.MINOR' (e.g., '1.34')."
  }
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Whether the EKS API endpoint is publicly accessible"
}

variable "node_pools" {
  type        = list(string)
  default     = ["general-purpose"]
  description = "EKS Auto Mode node pools: general-purpose, system"

  validation {
    condition     = alltrue([for pool in var.node_pools : contains(["general-purpose", "system"], pool)])
    error_message = "Each node pool must be one of: general-purpose, system."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
