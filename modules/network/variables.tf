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

variable "vpc_connector_min_instances" {
  description = "Minimum VPC connector instances"
  type        = number
  default     = 2
}

variable "vpc_connector_max_instances" {
  description = "Maximum VPC connector instances"
  type        = number
  default     = 3
}

