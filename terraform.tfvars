# Copy this file to terraform.tfvars and fill in the values

project_id = "outty-prod"
region     = "us-east1"
zone       = "us-east1-b"
domain     = "outty.app"
environment = "prod"

# Database configuration
database_instance_tier = "db-f1-micro"
database_name          = "outty_db"
database_user          = "outty_user"
database_password      = "CHANGE_THIS_PASSWORD" # Use a strong password

# Cloud Run configuration
cloud_run_cpu          = "1"
cloud_run_memory       = "1Gi"
cloud_run_min_instances = 0
cloud_run_max_instances = 2

# Bastion configuration
bastion_machine_type = "e2-micro"

# Job Worker configuration
job_worker_machine_type = "e2-small"

# Service name
service_name = "outty-backend"

# GitHub configuration (optional - triggers will only be created if both are provided)
github_owner = ""  # e.g., "your-username" or "your-org"
github_repo  = ""  # e.g., "outty-backend"