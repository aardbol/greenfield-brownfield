# GCP GKE Module

Wraps [`terraform-google-modules/kubernetes-engine/google`](~> 44.0) autopilot-cluster submodule with opinionated defaults for production GKE Autopilot clusters.

## What is GKE Autopilot?

GKE Autopilot is a mode of operation that fully manages your cluster infrastructure so you can focus on your applications.

## Usage

### Greenfield: create a new fully managed cluster

```hcl
module "k8s" {
  source     = "../../modules/gcp/kubernetes"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "myapp"

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]

  # Private nodes with Cloud NAT for egress
  enable_private_nodes    = true
  enable_private_endpoint = false  # Keep API publicly accessible

  # Control plane CIDR for VPC peering
  master_ipv4_cidr_block = "10.0.0.0/28"

  # Allow public access to API (or restrict to specific CIDRs)
  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "public-access"
    }
  ]
}
```

### Brownfield: existing cluster

```hcl
module "k8s" {
  source     = "../../modules/gcp/kubernetes"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "passthrough"

  existing_cluster_name     = "my-existing-gke"
  existing_cluster_location = "europe-west1"
}
```

## Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Mode | Autopilot | GKE manages all compute |
| Private nodes | Enabled | Nodes use internal IPs only |
| Private endpoint | Disabled | API is publicly accessible |
| Master authorized networks | `[TOKEN_EXPIRED]/0` | Restrict in production |
| Release channel | `STABLE` | GKE manages all version upgrades |
| Workload Identity | Enabled | IAM-to-KSA binding |
| Vertical Pod Autoscaling | Enabled | Always enabled in Autopilot |
| Dataplane V2 | Enabled | Always enabled in Autopilot |
| Maintenance | Weekends 03:00-05:00 UTC | Off-peak |
| Logging | SYSTEM_COMPONENTS, WORKLOADS | Configurable via `logging_components` |
| Monitoring | SYSTEM_COMPONENTS | Configurable via `monitoring_components` |
| Deletion protection | Disabled | Enable for production |

## Observability

### Logging Components
Configure which GKE components expose logs:
- `SYSTEM_COMPONENTS`: System component logs
- `APISERVER`: API server logs
- `CONTROLLER_MANAGER`: Controller manager logs
- `SCHEDULER`: Scheduler logs
- `WORKLOADS`: Workload logs

### Monitoring Components
Configure which GKE components expose metrics:
- `SYSTEM_COMPONENTS`: System component metrics
- `APISERVER`, `SCHEDULER`, `CONTROLLER_MANAGER`: Control plane metrics
- `STORAGE`, `HPA`, `POD`, `DAEMONSET`, `DEPLOYMENT`, `STATEFULSET`: Workload metrics
- `KUBELET`, `CADVISOR`, `DCGM`, `JOBSET`: Node and job metrics

## Outputs

| Name | Type | Sensitive | Description |
|------|------|-----------|-------------|
| `cluster_name` | `string` | No | Cluster name |
| `cluster_endpoint` | `string` | Yes | API endpoint URL |
| `cluster_ca_certificate` | `string` | Yes | CA certificate (base64) |
| `cluster_location` | `string` | No | Region or zone |
| `cluster_region` | `string` | No | Cluster region |
| `master_version` | `string` | No | Current K8s version |
| `service_account` | `string` | No | Default node SA |
| `identity_namespace` | `string` | No | Workload Identity pool |
| `configure_kubectl` | `string` | No | CLI command |

## Prerequisites

- OpenTofu >= 1.11
- APIs: `container.googleapis.com`, `compute.googleapis.com`
- Service account with `roles/container.clusterAdmin`, `roles/iam.serviceAccountAdmin`
- For private nodes: Cloud NAT configured in the VPC (use the VPC module with `enable_cloud_nat = true`)