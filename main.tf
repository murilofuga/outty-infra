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
  #   bucket = "${var.project_id}-terraform-state"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Local values for computed configurations
locals {
  # Construct artifact registry image path dynamically
  artifact_registry_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.project_id}-repo/${var.service_name}:latest"
  
  # Construct secret name from environment if not explicitly provided
  db_secret_name = var.db_secret_name != null ? var.db_secret_name : "${upper(var.environment)}_DB_PASSWORD"
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
  environment             = var.environment
  db_secret_name          = local.db_secret_name
  # Using placeholder image - will be replaced when real image is pushed
  artifact_registry_image = local.artifact_registry_image
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id   = var.project_id
  region       = var.region
  service_name = module.compute.service_name
  domain       = "api.${var.domain}"

  depends_on = [
    module.compute
  ]
}

# DNS Module (Outputs load balancer IP for DNS configuration)
module "dns" {
  source = "./modules/dns"

  project_id      = var.project_id
  region          = var.region
  domain          = "api.${var.domain}"
  service_name    = module.compute.service_name
  load_balancer_ip = module.load_balancer.load_balancer_ip

  depends_on = [
    module.load_balancer
  ]
}

# Job Worker Module (VM for processing background jobs)
module "job_worker" {
  source = "./modules/job-worker"

  project_id              = var.project_id
  region                  = var.region
  zone                    = var.zone
  network                 = module.network.vpc_network_name
  subnet                  = module.network.subnet_name
  cloud_sql_instance      = module.database.instance_connection_name
  database_name           = var.database_name
  database_user           = var.database_user
  database_password       = var.database_password
  machine_type            = var.job_worker_machine_type
  environment             = var.environment
  db_secret_name          = local.db_secret_name
  artifact_registry_image = local.artifact_registry_image

  depends_on = [
    module.database,
    module.storage
  ]
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

