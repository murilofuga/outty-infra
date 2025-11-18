output "instance_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.instance.connection_name
}

output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.instance.name
}

output "private_ip_address" {
  description = "Cloud SQL private IP address"
  value       = google_sql_database_instance.instance.private_ip_address
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.database.name
}

output "database_user" {
  description = "Database user"
  value       = google_sql_user.user.name
}

