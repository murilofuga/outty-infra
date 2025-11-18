output "domain_mapping_name" {
  description = "Domain mapping resource name"
  value       = google_cloud_run_domain_mapping.api_domain.name
}

output "domain_url" {
  description = "Custom domain URL"
  value       = "https://${google_cloud_run_domain_mapping.api_domain.name}"
}

output "dns_records" {
  description = "DNS records that need to be added to Namecheap"
  value = length(google_cloud_run_domain_mapping.api_domain.status) > 0 && length(google_cloud_run_domain_mapping.api_domain.status[0].resource_records) > 0 ? {
    for record in google_cloud_run_domain_mapping.api_domain.status[0].resource_records : record.type => {
      name   = record.name
      type   = record.type
      rrdata = record.rrdata
    }
  } : {}
}

output "domain_status" {
  description = "Status of domain mapping"
  value = length(google_cloud_run_domain_mapping.api_domain.status) > 0 && length(google_cloud_run_domain_mapping.api_domain.status[0].conditions) > 0 ? google_cloud_run_domain_mapping.api_domain.status[0].conditions[0].status : "Unknown"
}

output "domain_ready" {
  description = "Whether the domain mapping is ready (DNS records must be added first)"
  value = length(google_cloud_run_domain_mapping.api_domain.status) > 0 && length(google_cloud_run_domain_mapping.api_domain.status[0].conditions) > 0 ? google_cloud_run_domain_mapping.api_domain.status[0].conditions[0].status == "True" : false
}

