variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "network" {
  description = "VPC Network name"
  type        = string
}

variable "subnet" {
  description = "Subnet name"
  type        = string
}

variable "cloud_sql_instance" {
  description = "Cloud SQL instance connection name"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_user" {
  description = "Database user"
  type        = string
}

variable "database_password" {
  description = "Database password (from Secret Manager)"
  type        = string
  sensitive   = true
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-small"
}

variable "artifact_registry_image" {
  description = "Docker image from Artifact Registry (e.g., us-east1-docker.pkg.dev/project/repo/image:tag)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "db_secret_name" {
  description = "Secret Manager secret name for database password"
  type        = string
}
