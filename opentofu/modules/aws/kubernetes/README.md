# AWS EKS Module

Wraps [`terraform-aws-modules/eks/aws`](~> 21.0) with opinionated defaults for production EKS clusters using **EKS Auto Mode**.

## What is EKS Auto Mode?

EKS Auto Mode provides **fully managed compute**. AWS handles node provisioning, scaling, patching, and lifecycle.

## Usage

### Greenfield: create a new fully managed cluster

```hcl
module "vpc" {
  source = "../../modules/aws/vpc"
  name   = "myapp"
  # ...
}

module "k8s" {
  source = "../../modules/aws/kubernetes"

  name       = "${var.name}-cluster"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_pools = ["general-purpose"]

  tags = {
    environment = "production"
  }
}
```

### Brownfield: existing cluster

```hcl
module "k8s" {
  source = "../../modules/aws/kubernetes"

  name                  = "passthrough"
  vpc_id                = data.aws_vpc.existing.id
  subnet_ids            = data.aws_subnets.existing.ids
  existing_cluster_name = "my-existing-cluster"
}
```

## Node Pools

Node pools are named sets of compute resources that AWS automatically manages. 
All instances are ephemeral and AWS selects optimal instance types based on workload requirements.

| Pool | Purpose | Enabled by Default |
| --- | --- | --- |
| general-purpose | Default workloads (web apps, APIs, batch jobs) | ✅ Yes |
| system | Critical cluster add-ons and DaemonSets | ⬜ No |

## Logging

Crucial logs are enabled by default to minimize cost and noise while maintaining security visibility.

| Log Type | Category | Default |
| --- | --- | --- |
| api | **Crucial** | ✅ Yes |
| audit | **Crucial** | ✅ Yes |
| authenticator | **Crucial** | ✅ Yes |
| controllerManager | Optional | ❌ No |
| scheduler | Optional | ❌ No |

## Outputs

| Name | Type | Sensitive | Description |
| --- | --- | --- | --- |
| cluster_name | string | No | Cluster name |
| cluster_endpoint | string | No | API endpoint |
| cluster_ca_certificate | string | **Yes** | CA cert (base64) |
| cluster_arn | string | No | Cluster ARN |
| cluster_version | string | No | K8s version |
| cluster_security_group_id | string | No | EKS control plane security group |
| oidc_provider_arn | string | No | For IRSA |
| oidc_provider_url | string | No | OIDC issuer URL |
| configure_kubectl | string | No | CLI command |
| cluster_auth_token | string | **Yes** | Temporary auth token (brownfield only, 15 min TTL) |
| auto_mode_enabled | bool | No | Whether EKS Auto Mode is enabled |
| node_pools_enabled | list(string) | No | Node pools active in the cluster |

## Prerequisites

- OpenTofu >= 1.11
- AWS credentials with `eks:CreateCluster`, `iam:CreateRole`, etc.
- VPC with private subnets tagged `kubernetes.io/role/internal-elb = "1"`
- Subnets tagged `kubernetes.io/role/internal-elb = "1"` for internal load balancers