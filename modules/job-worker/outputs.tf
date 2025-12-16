output "instance_name" {
  description = "Name of the job worker VM instance"
  value       = google_compute_instance.job_worker.name
}

output "instance_zone" {
  description = "Zone of the job worker VM instance"
  value       = google_compute_instance.job_worker.zone
}

output "service_account_email" {
  description = "Email of the job worker service account"
  value       = google_service_account.job_worker.email
}
