variable "name" {
  type        = string
  description = "Name prefix for all VPC resources"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]*$", var.name))
    error_message = "The name must start with alphanumeric and contain only alphanumeric, hyphens, and underscores."
  }
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "The cidr_block must be a valid CIDR notation (e.g., 10.0.0.0/16)."
  }
}

variable "azs" {
  type        = list(string)
  default     = []
  description = "Availability zone names (e.g., ['us-west-2a', 'us-west-2b']). Empty = auto-discover 3."

  validation {
    condition     = alltrue([for az in var.azs : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))])
    error_message = "Each AZ must be a valid AWS availability zone identifier (e.g., us-west-2a, eu-central-1b)."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  description = "CIDR blocks for private subnets (one per AZ)"

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each private_subnet_cidrs element must be a valid CIDR notation."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  description = "CIDR blocks for public subnets (one per AZ)"

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each public_subnet_cidrs element must be a valid CIDR notation."
  }
}

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Whether to create NAT gateways for private subnet egress"
}

variable "one_nat_gateway_per_az" {
  type        = bool
  default     = true
  description = "Create one NAT gateway per AZ (HA)"
}

variable "enable_ipv6" {
  type        = bool
  default     = false
  description = "Whether to enable IPv6 on the VPC"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all VPC resources"
}

# ── Brownfield

variable "existing_vpc_id" {
  type        = string
  default     = null
  description = "Existing VPC ID. When set, no new VPC is created."
}

variable "existing_private_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Existing private subnet IDs when using an existing VPC."
}

variable "existing_public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Existing public subnet IDs when using an existing VPC."
}

variable "auto_discover_existing_subnets" {
  type        = bool
  default     = false
  description = "Auto-discover subnets by EKS tags from the existing VPC instead of providing IDs explicitly."
}

# ── Logging

variable "enable_flow_log" {
  type        = bool
  default     = true
  description = "Enable VPC Flow Log to CloudWatch. Disabled by default"
}

variable "flow_log_traffic_type" {
  type        = string
  default     = "REJECT"
  description = "Traffic to log: ACCEPT, REJECT, or ALL. REJECT captures security-relevant failures at minimal cost."

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "Must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention in days. Short retention by default keeps costs down."

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_log_retention_days)
    error_message = "Must be a valid CloudWatch retention period."
  }
}

variable "flow_log_log_group_name" {
  type        = string
  default     = null
  description = "Custom CloudWatch log group name. Defaults to /vpc/flowlog/{vpc_id}."
}
