# Greenfield & Brownfield Deployments

Multi-cloud OpenTofu modules for provisioning VPCs and Kubernetes clusters on **GCP** and **AWS**, with deployments for two customer scenarios. Includes a Helm chart for the application workload.

## Structure

```
opentofu/
├── modules/
│   ├── gcp/
│   │   ├── vpc/            ←  Wraps terraform-google-modules/network ~> 18.0
│   │   └── kubernetes/     ←  Wraps terraform-google-modules/kubernetes-engine ~> 44.0 (Autopilot)
│   └── aws/
│       ├── vpc/            ←  Wraps terraform-aws-modules/vpc ~> 6.0
│       └── kubernetes/     ←  Wraps terraform-aws-modules/eks ~> 21.0 (EKS Auto Mode)
├── deployments/
│   ├── customer-acmecorp/  ←  Greenfield: everything created from scratch
│   │   ├── gcp/            ←    GKE Autopilot in a new VPC with Cloud NAT
│   │   └── aws/            ←    EKS Auto Mode in a new VPC with NAT Gateway
│   └── customer-othercorp/ ←  Brownfield: existing VPC, new Kubernetes cluster
│       ├── gcp/            ←    GKE Autopilot in an existing VPC
│       └── aws/            ←    EKS Auto Mode in an existing VPC
helm/
├── Chart.yaml              ←  Helm chart: image, resources, probes, SA, HPA, NetworkPolicy
├── values.yaml             ←  Tune replicas, resources, env, ingress, network policy, affinity
└── templates/              ←  Deployment, Service, ServiceAccount, HPA, Ingress, NetworkPolicy, helpers, NOTES
```

## Deployment Types

| Scenario | customer-acmecorp (greenfield) | customer-othercorp (brownfield) |
|----------|-------------------------------|---------------------------------|
| VPC      | Created from scratch | References existing VPC by ID |
| Subnets  | Created from CIDRs | Auto-discovers by EKS/GKE tags or explicit list |
| Cluster  | New EKS Auto Mode / GKE Autopilot | New EKS Auto Mode / GKE Autopilot |
| NAT      | NAT Gateway (AWS) / Cloud NAT (GCP) | Managed externally |

### Module features

| Feature | GCP | AWS |
|---------|-----|-----|
| Greenfield | ✅ `existing_network_name = null` | ✅ `existing_vpc_id = null` |
| Brownfield VPC | `existing_network_name`, `existing_*_subnet_names` | `existing_vpc_id`, `existing_private_subnet_ids` |
| Brownfield cluster | `existing_cluster_name` | `existing_cluster_name` |
| Private nodes | `enable_private_nodes` (default: true) | `cluster_endpoint_public_access` (default: true) |
| Cloud NAT | `enable_cloud_nat` | `enable_nat_gateway` |
| Workload Identity / IRSA | ✅ Workload Identity | ✅ OIDC provider & IRSA |
| Compute | GKE Autopilot (fully managed) | EKS Auto Mode (fully managed) |

## Quick Start

### customer-acmecorp (greenfield, GCP)

```bash
cd opentofu/deployments/customer-acmecorp/gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID
tofu init
tofu plan
tofu apply
```

### customer-acmecorp (greenfield, AWS)

```bash
cd opentofu/deployments/customer-acmecorp/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VPC CIDRs
tofu init
tofu plan
tofu apply
```

### customer-othercorp (brownfield, GCP)

```bash
cd opentofu/deployments/customer-othercorp/gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your existing network name and subnets
tofu init
tofu plan
tofu apply
```

### customer-othercorp (brownfield, AWS)

```bash
cd opentofu/deployments/customer-othercorp/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your existing VPC ID
tofu init
tofu plan
tofu apply
```

### Application (Helm)

Basic install:
```bash
helm install deployment-app ./helm --namespace sre-interview --create-namespace
```

With ingress enabled (requires Traefik or another ingress controller):
```bash
helm install deployment-app ./helm --namespace sre-interview \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=app.yourdomain.com
```

With network policy enabled (requires Calico, Cilium, or another CNI that enforces NetworkPolicies):
```bash
helm install deployment-app ./helm --namespace sre-interview \
  --set networkPolicy.enabled=true
```

Override resources per environment:
```bash
helm install deployment-app ./helm --namespace sre-interview \
  --set resources.requests.cpu=256m \
  --set resources.requests.memory=256Mi
```

## Helm chart defaults

| Parameter | Default | Description |
|-----------|---------|-------------|
| `image.repository` | `ghcr.io/e2b-dev/sre-interview` | Container image |
| `image.tag` | `latest` | Image tag |
| `replicaCount` | `1` | Pod replicas |
| `resources.requests` | CPU 256m, Memory 256Mi | Resource requests |
| `resources.limits` | CPU none, Memory 1Gi | Resource limits (no CPU limit) |
| `service.type` | `ClusterIP` | Externally routed via Traefik |
| `service.port` | `8080` | Container port |
| `ingress.enabled` | `false` | Ingress — enable when an ingress controller is installed |
| `ingress.className` | `traefik` | Ingress class |
| `networkPolicy.enabled` | `false` | NetworkPolicy — enable when CNI supports enforcement |
| `autoscaling.enabled` | `false` | HPA (opt-in) |
| `pdb.enabled` | `false` | PodDisruptionBudget — enable for HA when replicaCount > 1 |

## Prerequisites
- GitHub Actions configured (optional — see CI workflows below)

- **OpenTofu >= 1.11**
- **Helm >= 3.0**
- Cloud provider credentials configured
- Required APIs enabled per module README

## Design Decisions

1. **Greenfield/brownfield via count** — Each module uses `var.existing_* == null` to decide whether to create resources (`count = create ? 1 : 0`) or surface data sources
2. **Ingress via load balancer** — Node-level ingress is handled by a Kubernetes ingress controller (e.g., Traefik) via a cloud load balancer. Direct node port exposure is not used. The cluster security groups / firewall rules therefore don't open HTTP(S) to node instances
3. **EKS Auto Mode & GKE Autopilot** — Both compute layers are fully managed by the cloud provider
4. **Official upstream modules** — We wrap well-maintained community modules rather than writing raw resources
5. **Per-module READMEs** — Each module documents its own variables, outputs, and usage
6. **Optional NetworkPolicy** — Restricts pod access to only the ingress controller and DNS, gated by `networkPolicy.enabled` to avoid breaking clusters without a CNI that enforces policies

## CI Workflows

Two GitHub Actions workflows run on pull requests and pushes to `main`:

### `.github/workflows/tofu-validate.yaml`

| Job | What it does |
|-----|-------------|
| `fmt` | `tofu fmt -check -recursive .` — fails on unformatted code |
| `validate-modules` | `tofu init && tofu validate` for each module (4 matrix jobs: aws vpc/k8s, gcp vpc/k8s) |
| `validate-deployments` | `tofu init && tofu validate` for each deployment (4 matrix jobs: acmecorp aws/gcp, othercorp aws/gcp). Continues on error — deployments require `.tfvars` to fully validate |

### `.github/workflows/helm-lint.yaml`

| Job | What it does |
|-----|-------------|
| `lint` | `helm lint .` — chart structure and values validation |
| `template` | Renders the chart under 3 scenarios (default, full-turbo with ingress/HPA/NetworkPolicy/PDB, resource bump) to catch template errors |
| `kubeconform` | Pipes rendered templates through `kubeconform` against K8s 1.32 to validate against the Kubernetes schema |

### Running locally

```bash
# OpenTofu
tofu fmt -check -recursive opentofu/
tofu init -backend=false opentofu/modules/aws/vpc && tofu validate opentofu/modules/aws/vpc

# Helm
helm lint helm/
helm template test-release helm/ | kubeconform --kubernetes-version 1.34.0 --strict --ignore-missing-schemas
```
