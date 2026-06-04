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

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "Must be a valid CIDR notation."
  }
}

variable "azs" {
  type        = list(string)
  default     = []
  description = "Availability zone names. Empty = auto-discover 3."

  validation {
    condition     = alltrue([for az in var.azs : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))])
    error_message = "Each AZ must be a valid AWS availability zone identifier."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  description = "CIDR blocks for private subnets"

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each must be a valid CIDR notation."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  description = "CIDR blocks for public subnets"

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each must be a valid CIDR notation."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
