terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Backend configuration - uncomment and configure after creating GCS bucket
  # backend "gcs" {
  #   bucket = "outty-prod-terraform-state"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Network Module
module "network" {
  source = "./modules/network"

  project_id = var.project_id
  region     = var.region
  zone       = var.zone
}

# Database Module
module "database" {
  source = "./modules/database"

  project_id          = var.project_id
  region              = var.region
  network             = module.network.vpc_network_name
  database_name       = var.database_name
  database_user       = var.database_user
  database_password   = var.database_password
  instance_tier       = var.database_instance_tier

  depends_on = [
    module.network.private_vpc_connection
  ]
}

# Storage Module (includes both Cloud Storage and Artifact Registry)
module "storage" {
  source = "./modules/storage"

  project_id = var.project_id
  region     = var.region
}

# Bastion Module
module "bastion" {
  source = "./modules/bastion"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  network           = module.network.vpc_network_name
  subnet            = module.network.subnet_name
  database_instance = module.database.instance_connection_name
  machine_type      = var.bastion_machine_type
  ssh_public_key    = var.bastion_ssh_public_key
}

# Cloud Run Module (using placeholder image - will be updated via CI/CD)
module "compute" {
  source = "./modules/compute"

  project_id              = var.project_id
  region                  = var.region
  service_name            = var.service_name
  vpc_connector           = module.network.vpc_connector_name
  cloud_sql_instance      = module.database.instance_connection_name
  database_name           = var.database_name
  database_user           = var.database_user
  database_password       = var.database_password
  cpu                     = var.cloud_run_cpu
  memory                  = var.cloud_run_memory
  min_instances           = var.cloud_run_min_instances
  max_instances           = var.cloud_run_max_instances
  # Using placeholder image - will be replaced when real image is pushed
  artifact_registry_image = "us-east1-docker.pkg.dev/outty-prod/outty-prod-repo/outty-backend:latest"
}

# CI/CD Module
module "ci_cd" {
  source = "./modules/ci-cd"

  project_id              = var.project_id
  region                  = var.region
  service_name            = var.service_name
  cloud_run_service       = module.compute.service_name
  artifact_registry_id    = module.storage.repository_id
  cloud_sql_instance      = module.database.instance_connection_name
  database_name           = var.database_name
  database_user           = var.database_user
  database_password       = var.database_password
  vpc_connector           = module.network.vpc_connector_name
  cpu                     = var.cloud_run_cpu
  memory                  = var.cloud_run_memory
  min_instances           = var.cloud_run_min_instances
  max_instances           = var.cloud_run_max_instances
  github_owner            = var.github_owner
  github_repo             = var.github_repo
}

