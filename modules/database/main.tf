# Random password for database (if not provided)
resource "random_password" "db_password" {
  count   = var.database_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Cloud SQL Instance
resource "google_sql_database_instance" "instance" {
  name             = "${var.project_id}-mysql"
  database_version = "MYSQL_8_0"
  region           = var.region
  project          = var.project_id

  settings {
    tier                        = var.instance_tier
    availability_type           = "ZONAL"
    deletion_protection_enabled = false

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      binary_log_enabled             = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                                = "projects/${var.project_id}/global/networks/${var.network}"
      enable_private_path_for_google_cloud_services = true
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }

  deletion_protection = false
}

# Database
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.instance.name
  project  = var.project_id
}

# Database User
resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.instance.name
  password = var.database_password != "" ? var.database_password : random_password.db_password[0].result
  project  = var.project_id
}

