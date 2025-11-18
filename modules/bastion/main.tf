# Service Account for Bastion
resource "google_service_account" "bastion" {
  account_id   = "bastion-sa"
  display_name = "Bastion Service Account"
  project      = var.project_id
}

# Grant Cloud SQL Client role
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

# Compute Instance
resource "google_compute_instance" "bastion" {
  name         = "${var.project_id}-bastion"
  machine_type  = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["bastion"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "projects/${var.project_id}/global/networks/${var.network}"
    subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.subnet}"

    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  metadata = var.ssh_public_key != "" ? {
    ssh-keys = var.ssh_public_key
  } : {}

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get install -y nano mysql-client

    # Install Cloud SQL Proxy
    CLOUD_SQL_PROXY_VERSION="v2.14.0"
    URL="https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/$${CLOUD_SQL_PROXY_VERSION}"
    curl "$$URL/cloud-sql-proxy.linux.amd64" -o /usr/local/bin/cloud-sql-proxy
    chmod +x /usr/local/bin/cloud-sql-proxy

    # Create systemd service
    cat <<SERVICE > /etc/systemd/system/cloud-sql-proxy.service
[Unit]
Description=Google Cloud SQL Proxy
Requires=networking.service
After=networking.service

[Service]
Type=simple
RuntimeDirectory=cloud-sql-proxy
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/cloud-sql-proxy --private-ip --address 0.0.0.0 --port 3306 ${var.database_instance}
Restart=always
StandardOutput=journal
User=root

[Install]
WantedBy=multi-user.target
SERVICE

    # Enable and start service
    systemctl daemon-reload
    systemctl enable cloud-sql-proxy
    systemctl start cloud-sql-proxy
  EOF
}

