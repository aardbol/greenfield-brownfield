data "google_client_config" "default" {}

# ── VPC module in brownfield mode (existing network)

module "vpc" {
  source = "../../../modules/gcp/vpc"

  name       = "${var.customer_name}-vpc"
  project_id = var.project_id
  region     = var.region

  existing_network_name         = var.existing_network_name
  existing_private_subnet_names = var.existing_private_subnet_names
  existing_public_subnet_names  = var.existing_public_subnet_names

  labels = var.tags
}

# ── GKE cluster (greenfield — k8s needs installing in existing VPC)

module "k8s" {
  source = "../../../modules/gcp/kubernetes"

  name       = "${var.customer_name}-cluster"
  project_id = var.project_id
  region     = var.region

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]

  # GKE secondary ranges — if the existing subnet already has them, pass names here
  # Leave null if GKE should auto-allocate (subnet must have no secondary ranges)
  ip_range_pods_name     = var.ip_range_pods_name
  ip_range_services_name = var.ip_range_services_name

  release_channel    = var.gke_release_channel
  kubernetes_version = var.gke_kubernetes_version

  enable_private_nodes    = var.gke_private_nodes
  enable_private_endpoint = false
  master_ipv4_cidr_block  = "pii_494b19c3-f75b-4e79-aa0d-80060fdea3bc/28"

  master_authorized_networks = var.gke_private_nodes ? [
    {
      cidr_block   = "pii_26251630-f7ff-4457-b5e3-bc1b07303f57/0"
      display_name = "everyone"
    },
  ] : []

  # NOTE: existing_cluster_name is NOT set — this creates a NEW cluster
  # inside the existing VPC (brownfield VPC, greenfield k8s)

  tags = var.tags
}
