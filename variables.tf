variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "outty-prod"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-east1-b"
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "outty.app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "database_instance_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "outty_db"
}

variable "database_user" {
  description = "Database user"
  type        = string
  default     = "outty_user"
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "cloud_run_cpu" {
  description = "Cloud Run CPU allocation"
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Cloud Run memory allocation"
  type        = string
  default     = "1Gi"
}

variable "cloud_run_min_instances" {
  description = "Minimum Cloud Run instances"
  type        = number
  default     = 0
}

variable "cloud_run_max_instances" {
  description = "Maximum Cloud Run instances"
  type        = number
  default     = 2
}

variable "bastion_machine_type" {
  description = "Bastion VM machine type"
  type        = string
  default     = "e2-micro"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "outty-backend"
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "bastion_ssh_public_key" {
  description = "SSH public key for bastion access (format: 'user:key')"
  type        = string
  default     = ""
}

variable "job_worker_machine_type" {
  description = "Job worker VM machine type"
  type        = string
  default     = "e2-small"
}

variable "db_secret_name" {
  description = "Secret Manager secret name for database password. If not provided, will be constructed from environment (e.g., PROD_DB_PASSWORD, DEV_DB_PASSWORD)"
  type        = string
  default     = null
}

