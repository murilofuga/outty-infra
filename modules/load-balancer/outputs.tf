output "load_balancer_ip" {
  description = "Static IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip_name" {
  description = "Name of the static IP address resource"
  value       = google_compute_global_address.lb_ip.name
}

output "ssl_certificate_name" {
  description = "Name of the managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.api_ssl_cert.name
}

output "ssl_certificate_status_note" {
  description = "Note about SSL certificate status"
  value       = "Check certificate status with: gcloud compute ssl-certificates describe ${google_compute_managed_ssl_certificate.api_ssl_cert.name} --global --format='value(managed.status)'"
}

output "forwarding_rule_name" {
  description = "Name of the global forwarding rule"
  value       = google_compute_global_forwarding_rule.cloud_run_forwarding_rule.name
}

