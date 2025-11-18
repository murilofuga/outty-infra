variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "domain" {
  description = "Custom domain name (e.g., api.outty.app)"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

