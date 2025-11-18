# Cloud Build Service Account (uses default compute service account)
data "google_project" "project" {
  project_id = var.project_id
}

# Grant Cloud Run Admin role to Cloud Build service account
resource "google_project_iam_member" "cloud_build_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Grant Service Account User role
resource "google_project_iam_member" "cloud_build_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Grant Artifact Registry Writer role
resource "google_project_iam_member" "cloud_build_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Cloud Build Triggers are managed manually in GCP Console
# The triggers (prod-release-trigger and prod-deploy-trigger) already exist
# and are configured for manual invocation only.
# 
# To update them, use the GCP Console or gcloud CLI:
# - gcloud builds triggers describe prod-release-trigger --region=us-east1
# - gcloud builds triggers update ...
#
# Note: Terraform cannot easily manage triggers that use source_to_build with
# GITHUB repo_type without the repository being connected via Cloud Build connections API.

