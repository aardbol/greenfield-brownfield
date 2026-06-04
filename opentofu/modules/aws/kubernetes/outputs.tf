locals {
  kubeconfig_cmd_create   = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
  kubeconfig_cmd_existing = var.existing_cluster_name != null ? "aws eks update-kubeconfig --name ${var.existing_cluster_name} --region ${var.region}" : ""
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = local.create_cluster ? module.eks.cluster_name : var.existing_cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint URL"
  value       = local.create_cluster ? module.eks.cluster_endpoint : data.aws_eks_cluster.existing[0].endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate"
  value       = local.create_cluster ? module.eks.cluster_certificate_authority_data : data.aws_eks_cluster.existing[0].certificate_authority[0].data
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = local.create_cluster ? module.eks.cluster_arn : data.aws_eks_cluster.existing[0].arn
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = local.create_cluster ? module.eks.cluster_version : data.aws_eks_cluster.existing[0].version
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = local.create_cluster ? module.eks.cluster_security_group_id : null
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IAM roles for service accounts (IRSA)"
  value       = local.create_cluster ? module.eks.oidc_provider_arn : null
}

output "oidc_provider_url" {
  description = "OIDC provider URL for IAM roles for service accounts (IRSA)"
  value       = local.create_cluster ? module.eks.cluster_oidc_issuer_url : null
}

output "node_security_group_id" {
  description = "Node security group ID"
  value       = local.create_cluster ? module.eks.node_security_group_id : null
}

output "configure_kubectl" {
  description = "Command to configure kubectl for this cluster"
  value       = local.create_cluster ? local.kubeconfig_cmd_create : local.kubeconfig_cmd_existing
}
