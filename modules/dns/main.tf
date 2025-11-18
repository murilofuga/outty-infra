# Cloud Run Domain Mapping
resource "google_cloud_run_domain_mapping" "api_domain" {
  name     = var.domain
  location = var.region
  project  = var.project_id

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = var.service_name
  }

  # Ignore metadata changes (annotations and labels are managed by GCP)
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

