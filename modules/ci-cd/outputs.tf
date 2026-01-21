output "cloud_build_service_account" {
  description = "Cloud Build service account email"
  value       = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Triggers are managed manually - IDs can be retrieved via:
# gcloud builds triggers describe {environment}-release-trigger --region={region} --format="value(id)"
# gcloud builds triggers describe {environment}-deploy-trigger --region={region} --format="value(id)"
# Note: Trigger IDs are environment-specific and should be configured per environment
output "release_trigger_id" {
  description = "Cloud Build trigger ID for {environment}-release-trigger (managed manually, environment-specific)"
  value       = "b288082d-921a-4d29-96be-f91e2cb92805"  # Hardcoded since trigger is managed manually - update per environment
}

output "deploy_trigger_id" {
  description = "Cloud Build trigger ID for {environment}-deploy-trigger (managed manually, environment-specific)"
  value       = "e7da8728-e562-4109-b13d-ceba47a479f8"  # Hardcoded since trigger is managed manually - update per environment
}

