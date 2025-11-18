# Service Account for Cloud Run
resource "google_service_account" "cloud_run" {
  account_id   = "${var.service_name}-sa"
  display_name = "Cloud Run Service Account for ${var.service_name}"
  project      = var.project_id
}

# Grant Cloud SQL Client role
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Grant Storage Object Viewer role (for reading from bucket)
resource "google_project_iam_member" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Grant Secret Manager Secret Accessor role (for reading PROD_DB_PASSWORD)
resource "google_project_iam_member" "secret_manager_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.cloud_run.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.artifact_registry_image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      env {
        name  = "SPRING_DATASOURCE_URL"
        value = "jdbc:mysql://localhost:3306/${var.database_name}?cloudSqlInstance=${var.cloud_sql_instance}&socketFactory=com.google.cloud.sql.mysql.SocketFactory&useSSL=false&serverTimezone=UTC"
      }

      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.database_user
      }

      env {
        name = "SPRING_DATASOURCE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = "PROD_DB_PASSWORD"
            version = "latest"
          }
        }
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "prod"
      }

      env {
        name  = "SERVER_PORT"
        value = "8080"
      }

      ports {
        container_port = 8080
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      startup_probe {
        http_get {
          path = "/actuator/health"
        }
        initial_delay_seconds = 90   # Increased to give more time for DB connection
        timeout_seconds       = 10
        period_seconds        = 10
        failure_threshold     = 15   # Total: 90s + (15 * 10s) = 240s (4 minutes)
      }

      liveness_probe {
        http_get {
          path = "/actuator/health/liveness"
        }
        initial_delay_seconds = 60
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
      }
    }

    vpc_access {
      connector = "projects/${var.project_id}/locations/${var.region}/connectors/${var.vpc_connector}"
      egress    = "PRIVATE_RANGES_ONLY"
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [var.cloud_sql_instance]
      }
    }
  }

  depends_on = [
    google_project_iam_member.cloud_sql_client
  ]

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# IAM policy - no public access
resource "google_cloud_run_service_iam_member" "no_public_access" {
  location = google_cloud_run_v2_service.service.location
  project  = var.project_id
  service  = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

