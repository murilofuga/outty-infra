#!/bin/bash
# ==============================================================================
# MAIN STARTUP SCRIPT
# ==============================================================================
set -e

# Variables injected by Terraform
# If using Terraform, these should be $${variable}. 
# If they appear as empty in the VM, check your Terraform mapping.
CLOUD_SQL_INSTANCE="${cloud_sql_instance}"
DATABASE_NAME="${database_name}"
DATABASE_USER="${database_user}"
ARTIFACT_REGISTRY_IMAGE="${artifact_registry_image}"
PROJECT_ID="${project_id}"
REGION="${region}"
DB_SECRET_NAME="${db_secret_name}"

# Redirect all script output to a log file for debugging
exec > >(tee -a /var/log/startup-script-main.log) 2>&1

echo "--- Starting job worker VM setup at $(date) ---"

# 1. Update and install Docker
apt-get update
apt-get install -y curl docker.io

# 2. Install Cloud SQL Proxy (if not present)
if [ ! -f /usr/local/bin/cloud-sql-proxy ]; then
    curl "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.14.0/cloud-sql-proxy.linux.amd64" -o /usr/local/bin/cloud-sql-proxy
    chmod +x /usr/local/bin/cloud-sql-proxy
fi

# 3. Configure Docker auth
gcloud auth configure-docker --quiet

# 4. Create directory for worker
mkdir -p /opt/outty-worker

# 5. Create Cloud SQL Proxy Service (Fixed for Ubuntu 22.04+)
cat <<SERVICE > /etc/systemd/system/cloud-sql-proxy.service
[Unit]
Description=Google Cloud SQL Proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloud-sql-proxy --private-ip --address 127.0.0.1 --port 3306 $${CLOUD_SQL_INSTANCE}
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable cloud-sql-proxy
systemctl restart cloud-sql-proxy

# 6. Create the Worker Wrapper Script
# We use 'EOF' (with quotes) to prevent the main shell from evaluating $ variables
cat <<'EOF' > /opt/outty-worker/start-worker.sh
#!/bin/bash
set -e

# These placeholders will be replaced by 'sed' in the next step
IMAGE="__IMAGE__"
DB_NAME="__DB_NAME__"
DB_USER="__DB_USER__"

echo "Fetching secret, authenticating docker and starting container..."

# 1. Force Docker to authenticate using the VM's service account identity
# This is the most reliable way for systemd services to pull from AR
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${REGION}-docker.pkg.dev

# 2. Fetch DB Password from Secret Manager
# Note: Use single $ because this runs on the VM shell
DB_PASSWORD=$(gcloud secrets versions access latest --secret=${DB_SECRET_NAME})

# Pull and Clean
docker pull $${IMAGE}
docker stop outty-worker || true
docker rm outty-worker || true

# Run the worker
# QUOTES around the URL are critical because of the '&' character
exec docker run --rm \
    --name outty-worker \
    --network host \
    -e SPRING_PROFILES_ACTIVE=worker \
    -e "SPRING_DATASOURCE_URL=jdbc:mysql://127.0.0.1:3306/$${DB_NAME}?useSSL=false&serverTimezone=UTC" \
    -e SPRING_DATASOURCE_USERNAME=$${DB_USER} \
    -e SPRING_DATASOURCE_PASSWORD="$${DB_PASSWORD}" \
    $${IMAGE}
EOF

# 7. Inject Terraform variables into the wrapper script
sed -i "s|__IMAGE__|$${ARTIFACT_REGISTRY_IMAGE}|g" /opt/outty-worker/start-worker.sh
sed -i "s|__DB_NAME__|$${DATABASE_NAME}|g" /opt/outty-worker/start-worker.sh
sed -i "s|__DB_USER__|$${DATABASE_USER}|g" /opt/outty-worker/start-worker.sh
chmod +x /opt/outty-worker/start-worker.sh

# 8. Create Outty Worker Service
cat <<SERVICE > /etc/systemd/system/outty-worker.service
[Unit]
Description=Outty Job Worker
Requires=cloud-sql-proxy.service
After=cloud-sql-proxy.service network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/outty-worker
ExecStart=/opt/outty-worker/start-worker.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable outty-worker
systemctl restart outty-worker

echo "--- Job worker VM setup completed at $(date) ---"

# ==============================================================================
# INSTALL OPS AGENT (LOGGING)
# ==============================================================================
# We use || true to ensure that if the agent fails to install, 
# the rest of the VM remains healthy and the app stays running.
echo "Installing Google Cloud Ops Agent..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh || true
if [ -f add-google-cloud-ops-agent-repo.sh ]; then
    bash add-google-cloud-ops-agent-repo.sh --also-install || true
    rm add-google-cloud-ops-agent-repo.sh
fi

echo "Startup script finished successfully."