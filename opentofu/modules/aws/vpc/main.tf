data "aws_availability_zones" "available" {
  count = local.create_vpc ? 1 : 0

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  create_vpc = var.existing_vpc_id == null
  azs        = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available[0].names, 0, 3)

  vpc_id_for_logs     = local.create_vpc ? module.vpc.vpc_id : var.existing_vpc_id
  flow_log_group_name = var.flow_log_log_group_name != null ? var.flow_log_log_group_name : "/vpc/flowlog/${local.vpc_id_for_logs}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = local.version_vpc_module

  name = var.name
  cidr = var.cidr_block
  azs  = local.azs

  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway     = var.enable_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_ipv6                                    = var.enable_ipv6
  public_subnet_assign_ipv6_address_on_creation  = var.enable_ipv6
  private_subnet_assign_ipv6_address_on_creation = var.enable_ipv6

  # EKS tags for service load balancers
  private_subnet_tags = merge(var.tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })
  public_subnet_tags = merge(var.tags, {
    "kubernetes.io/role/elb" = "1"
  })

  tags = var.tags

  lifecycle {
    enabled = local.create_vpc
  }
}

# ── Data sources for existing VPC (brownfield)

data "aws_vpc" "existing" {
  count = local.create_vpc ? 0 : 1

  id = var.existing_vpc_id
}

data "aws_subnets" "existing_private" {
  count = local.create_vpc || !var.auto_discover_existing_subnets ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_subnets" "existing_public" {
  count = local.create_vpc || !var.auto_discover_existing_subnets ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

# ── Logging

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = local.flow_log_group_name
  retention_in_days = var.flow_log_retention_days

  tags = var.tags

  lifecycle {
    enabled = var.enable_flow_log
  }
}

resource "aws_flow_log" "default" {
  vpc_id               = local.vpc_id_for_logs
  traffic_type         = var.flow_log_traffic_type
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn         = aws_iam_role.flow_log.arn

  tags = var.tags

  lifecycle {
    enabled = var.enable_flow_log
  }
}

resource "aws_iam_role" "flow_log" {
  name = "${var.name}-vpc-flow-log"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = var.tags

  lifecycle {
    enabled = var.enable_flow_log
  }
}

resource "aws_iam_role_policy" "flow_log" {
  name = "CloudWatchLogs"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })

  lifecycle {
    enabled = var.enable_flow_log
  }
}