output "instance_name" {
  description = "Bastion instance name"
  value       = google_compute_instance.bastion.name
}

output "external_ip" {
  description = "Bastion external IP address"
  value       = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "Bastion internal IP address"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}

