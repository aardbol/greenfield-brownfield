# GCP VPC Module

Wraps [`terraform-google-modules/network/google`](~> 18.0) with opinionated defaults for production GCP VPCs, plus Cloud NAT and VPC Flow Logs.

## Usage

### Greenfield: create a new VPC


```hcl
module "vpc" {
  source     = "../../modules/gcp/vpc"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "myapp"

  subnets = [
    {
      subnet_name           = "private-1"
      subnet_ip             = "10.0.0.0/24"
      subnet_private_access = true
    },
    {
      subnet_name           = "private-2"
      subnet_ip             = "10.0.1.0/24"
      subnet_private_access = true
    },
    {
      subnet_name           = "private-3"
      subnet_ip             = "10.0.2.0/24"
      subnet_private_access = true
    },
    {
      subnet_name           = "public-1"
      subnet_ip             = "10.0.101.0/24"
      subnet_private_access = false
    },
    {
      subnet_name           = "public-2"
      subnet_ip             = "10.0.102.0/24"
      subnet_private_access = false
    },
    {
      subnet_name           = "public-3"
      subnet_ip             = "10.0.103.0/24"
      subnet_private_access = false
    },
  ]

  # Enable Cloud NAT if you plan to use private GKE nodes
  enable_cloud_nat = true
}
```

### Brownfield: use an existing VPC and subnets

```hcl
module "vpc" {
  source     = "../../modules/gcp/vpc"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "passthrough"

  existing_network_name = "my-existing-vpc"
  existing_private_subnet_names = ["my-existing-private-subnet-1", "my-existing-private-subnet-2"]
  existing_public_subnet_names = ["my-existing-public-subnet-1", "my-existing-public-subnet-2"]
}
```

## Features

- **Greenfield**: Creates VPC + subnets + optional Cloud NAT
- **Brownfield**: Pass `existing_network_name` to surface outputs from an existing VPC
- **Cloud NAT**: Optional, for private GKE nodes.
- **Secondary ranges**: Pass `secondary_ranges` for GKE pod/service ranges
- **VPC Flow Logs**: Optional, with configurable sampling and filter expressions. Defaults to rejected traffic only.

Note: NAT IPs use `prevent_destroy = true` to avoid accidental loss of whitelisted addresses. Reducing `cloud_nat_static_ips` requires manual state intervention.

## Required APIs

```hcl
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
}
```

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `network_name` | `string` | VPC network name (created or existing) |
| `network_self_link` | `string` | VPC network self-link (URI) |
| `network_id` | `string` | VPC network numeric ID |
| `subnets_names` | `list(string)` | List of all subnetwork names |
| `subnets_self_links` | `map(string)` | Map of subnetwork names to their self-links |
| `subnets_ips` | `map(string)` | Map of subnetwork names to their IP CIDR ranges |
| `private_subnet_names` | `list(string)` | Private subnet names (subnets with private_ip_google_access) |
| `public_subnet_names` | `list(string)` | Public subnet names (subnets without private_ip_google_access) |
| `secondary_ranges` | `map(list(object))` | Map of subnet names to secondary IP ranges (for GKE pods/services) |
| `project_id` | `string` | GCP project ID (pass-through) |
| `region` | `string` | GCP region (pass-through) |
| `nat_ips` | `list(string)` | Static external IPs for Cloud NAT whitelisting |
| `nat_ip_self_links` | `list(string)` | Self-links of NAT IPs |
| `router_name` | `string` | Cloud Router name |
| `flow_log_bucket_id` | `string` | Cloud Logging bucket for flow logs (null if disabled) |
| `flow_log_sink_id` | `string` | Cloud Logging sink for flow logs (null if disabled) |

## Prerequisites

- OpenTofu >= 1.11
- Project with `compute.googleapis.com` and `logging.googleapis.com` enabled
- Service account with `roles/compute.networkAdmin`
