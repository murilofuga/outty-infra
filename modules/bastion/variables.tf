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
  description = "VPC Network Name"
  type        = string
}

variable "subnet" {
  description = "Subnet Name"
  type        = string
}

variable "database_instance" {
  description = "Cloud SQL instance connection name"
  type        = string
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-micro"
}

variable "ssh_public_key" {
  description = "SSH public key for bastion access (format: 'user:key')"
  type        = string
  default     = ""
}

