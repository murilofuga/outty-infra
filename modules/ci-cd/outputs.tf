output "cloud_build_service_account" {
  description = "Cloud Build service account email"
  value       = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Triggers are managed manually - IDs can be retrieved via:
# gcloud builds triggers describe prod-release-trigger --region=us-east1 --format="value(id)"
# gcloud builds triggers describe prod-deploy-trigger --region=us-east1 --format="value(id)"
output "prod_release_trigger_id" {
  description = "Cloud Build trigger ID for prod-release-trigger (managed manually)"
  value       = "b288082d-921a-4d29-96be-f91e2cb92805"  # Hardcoded since trigger is managed manually
}

output "prod_deploy_trigger_id" {
  description = "Cloud Build trigger ID for prod-deploy-trigger (managed manually)"
  value       = "e7da8728-e562-4109-b13d-ceba47a479f8"  # Hardcoded since trigger is managed manually
}

