output "vpc_network_id" {
  description = "VPC Network ID"
  value       = google_compute_network.vpc.id
}

output "vpc_network_name" {
  description = "VPC Network Name"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "Subnet Name"
  value       = google_compute_subnetwork.subnet.name
}

output "vpc_connector_id" {
  description = "VPC Connector ID"
  value       = google_vpc_access_connector.connector.id
}

output "vpc_connector_name" {
  description = "VPC Connector Name"
  value       = google_vpc_access_connector.connector.name
}

output "private_vpc_connection" {
  description = "Private VPC Connection for Cloud SQL"
  value       = google_service_networking_connection.private_vpc_connection.id
}

