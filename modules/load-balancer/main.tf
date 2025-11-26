# Static IP Address for Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.service_name}-lb-ip"
  project = var.project_id
}

# Serverless Network Endpoint Group (NEG) for Cloud Run
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "${var.service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = var.project_id

  cloud_run {
    service = var.service_name
  }
}

# Backend Service
# Note: Serverless NEGs (Cloud Run) don't support health checks
# Cloud Run manages its own health checks internally
resource "google_compute_backend_service" "cloud_run_backend" {
  name                  = "${var.service_name}-backend"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  enable_cdn            = false

  backend {
    group                 = google_compute_region_network_endpoint_group.cloud_run_neg.id
    balancing_mode        = "UTILIZATION"
    capacity_scaler       = 1.0
    max_utilization       = 0.8
  }

  # Health checks are not supported for Serverless NEGs
  # Cloud Run manages health checks internally

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map
resource "google_compute_url_map" "cloud_run_url_map" {
  name            = "${var.service_name}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.cloud_run_backend.id
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "api_ssl_cert" {
  name    = "${var.service_name}-ssl-cert"
  project = var.project_id

  managed {
    domains = [var.domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target HTTPS Proxy
resource "google_compute_target_https_proxy" "cloud_run_https_proxy" {
  name             = "${var.service_name}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.cloud_run_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.api_ssl_cert.id]
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "cloud_run_forwarding_rule" {
  name                  = "${var.service_name}-forwarding-rule"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.cloud_run_https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.id
}

