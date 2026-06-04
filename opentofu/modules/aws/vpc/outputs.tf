output "vpc_id" {
  description = "VPC ID (created or existing)"
  value       = local.create_vpc ? module.vpc.vpc_id : var.existing_vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = local.create_vpc ? module.vpc.vpc_cidr_block : data.aws_vpc.existing[0].cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = local.create_vpc ? module.vpc.private_subnets : (
    length(var.existing_private_subnet_ids) > 0 ? var.existing_private_subnet_ids : try(data.aws_subnets.existing_private[0].ids, [])
  )
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = local.create_vpc ? module.vpc.public_subnets : (
    length(var.existing_public_subnet_ids) > 0 ? var.existing_public_subnet_ids : try(data.aws_subnets.existing_public[0].ids, [])
  )
}

output "nat_public_ips" {
  description = "Public IPs of NAT gateways (if any)"
  value       = local.create_vpc ? module.vpc.nat_public_ips : null
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log (null if disabled)"
  value       = var.enable_flow_log ? aws_flow_log.default.id : null
}

output "flow_log_log_group_name" {
  description = "CloudWatch log group name for flow logs (null if disabled)"
  value       = var.enable_flow_log ? aws_cloudwatch_log_group.flow_logs.name : null
}

output "flow_log_log_group_arn" {
  description = "CloudWatch log group ARN for flow logs (null if disabled)"
  value       = var.enable_flow_log ? aws_cloudwatch_log_group.flow_logs.arn : null
}