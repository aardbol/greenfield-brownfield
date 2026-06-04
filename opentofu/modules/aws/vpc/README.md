# AWS VPC Module

Wraps [`terraform-aws-modules/vpc/aws`](~> 6.0) with opinionated defaults for production AWS VPCs.

## Usage

### Greenfield: create a new VPC

```hcl
module "vpc" {
  source = "../../modules/aws/vpc"
  name   = "myapp"

  cidr_block = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    environment = "production"
    managed_by  = "opentofu"
  }
}
```

### Brownfield: use an existing VPC and subnets

```hcl
module "vpc" {
  source = "../../modules/aws/vpc"
  name   = "passthrough"

  existing_vpc_id           = "vpc-0a1b2c3d4e5f67890"
  existing_private_subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  existing_public_subnet_ids  = ["subnet-ddd", "subnet-eee", "subnet-fff"]
}
```

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `vpc_id` | `string` | VPC ID |
| `vpc_cidr_block` | `string` | VPC CIDR |
| `private_subnet_ids` | `list(string)` | Private subnet IDs |
| `public_subnet_ids` | `list(string)` | Public subnet IDs |
| `azs` | `list(string)` | AZs used |
| `nat_public_ips` | `list(string)` | NAT gateway public IPs |
| `flow_log_id` | `string` | VPC Flow Log ID (null if disabled) |
| `flow_log_log_group_name` | `string` | CloudWatch log group name for flow logs (null if disabled) |
| `flow_log_log_group_arn` | `string` | CloudWatch log group ARN for flow logs (null if disabled) |

## Prerequisites

- OpenTofu >= 1.11
- AWS credentials configured
