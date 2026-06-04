data "google_client_config" "default" {}

module "vpc" {
  source = "../../../modules/gcp/vpc"

  name       = "${var.customer_name}-vpc"
  project_id = var.project_id
  region     = var.region

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

  secondary_ranges = {
    "${var.customer_name}-gke" = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.0.16.0/20"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.0.15.0/24"
      },
    ]
  }

  labels = var.tags
}

module "k8s" {
  source = "../../../modules/gcp/kubernetes"

  name       = "${var.customer_name}-cluster"
  project_id = var.project_id
  region     = var.region

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]

  ip_range_pods_name     = "pods"
  ip_range_services_name = "services"

  tags = var.tags
}
