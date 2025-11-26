output "vpc_network_id" {
  description = "VPC Network ID"
  value       = module.network.vpc_network_id
}

output "vpc_connector_name" {
  description = "VPC Connector Name"
  value       = module.network.vpc_connector_name
}

output "cloud_sql_instance_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = module.database.instance_connection_name
  sensitive   = true
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = module.database.private_ip_address
}

output "cloud_run_service_url" {
  description = "Cloud Run service URL"
  value       = module.compute.service_url
}

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = module.compute.service_name
}

output "bastion_external_ip" {
  description = "Bastion VM external IP address"
  value       = module.bastion.external_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "gcloud compute ssh ${module.bastion.instance_name} --zone=${var.zone} --project=${var.project_id}"
}

output "storage_bucket_name" {
  description = "Cloud Storage bucket name"
  value       = module.storage.bucket_name
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository ID"
  value       = module.storage.repository_id
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = module.storage.repository_url
}

output "load_balancer_ip" {
  description = "Load balancer static IP address (use this for DNS A record)"
  value       = module.load_balancer.load_balancer_ip
}

output "ssl_certificate_status_note" {
  description = "Command to check SSL certificate status"
  value       = module.load_balancer.ssl_certificate_status_note
}

output "ssl_certificate_name" {
  description = "Name of the managed SSL certificate"
  value       = module.load_balancer.ssl_certificate_name
}

output "custom_domain_url" {
  description = "Custom domain URL (HTTPS via load balancer)"
  value       = module.dns.domain_url
}

output "dns_records" {
  description = "DNS A record that needs to be added to your DNS provider (e.g., Namecheap)"
  value       = module.dns.dns_records
}

output "load_balancer_forwarding_rule" {
  description = "Name of the global forwarding rule"
  value       = module.load_balancer.forwarding_rule_name
}

