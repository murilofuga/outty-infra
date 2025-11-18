# Cloud Storage Bucket
resource "google_storage_bucket" "bucket" {
  name          = "${var.project_id}-storage"
  location      = var.region
  project       = var.project_id
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "repository" {
  location      = var.region
  repository_id = "${var.project_id}-repo"
  description   = "Docker repository for ${var.project_id}"
  format        = "DOCKER"
  project       = var.project_id
}

