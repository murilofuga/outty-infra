# Service Account for Job Worker VM
resource "google_service_account" "job_worker" {
  account_id   = "job-worker-sa"
  display_name = "Job Worker Service Account"
  project      = var.project_id
}

# Grant Cloud SQL Client role
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.job_worker.email}"
}

# Grant Storage Object Admin role (for downloading JAR from Cloud Storage if needed)
resource "google_project_iam_member" "storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.job_worker.email}"
}

# Grant Secret Manager Secret Accessor role (for reading database password secret)
resource "google_project_iam_member" "secret_manager_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.job_worker.email}"
}

# Grant Artifact Registry Reader role (for pulling Docker images)
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.job_worker.email}"
}

# Compute Instance for Job Worker
resource "google_compute_instance" "job_worker" {
  name         = "${var.project_id}-job-worker"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["job-worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "projects/${var.project_id}/global/networks/${var.network}"
    subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.subnet}"

    # No public IP - VM is in private subnet
    # access_config {
    #   // Ephemeral public IP
    # }
  }

  service_account {
    email  = google_service_account.job_worker.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    cloud_sql_instance     = var.cloud_sql_instance
    database_name          = var.database_name
    database_user          = var.database_user
    artifact_registry_image = var.artifact_registry_image
    project_id             = var.project_id
    region                  = var.region
    db_secret_name          = var.db_secret_name
  })

  # Allow VM to be stopped/started without Terraform destroying it
  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }
}
