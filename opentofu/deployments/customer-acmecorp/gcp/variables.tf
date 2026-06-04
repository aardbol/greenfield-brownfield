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

variable "gke_release_channel" {
  type        = string
  default     = "STABLE"
  description = "GKE release channel"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.gke_release_channel)
    error_message = "Must be one of: UNSPECIFIED, RAPID, REGULAR, STABLE."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all resources"
}
