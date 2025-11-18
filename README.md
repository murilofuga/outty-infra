# Outty GCP Infrastructure

Terraform configuration for deploying Outty application infrastructure on Google Cloud Platform.

## Architecture

- **Cloud Run**: Serverless backend service (Spring Boot)
- **Cloud SQL**: MySQL 8.0 database (db-f1-micro)
- **Bastion VM**: e2-micro instance for database access via Cloud SQL Proxy
- **VPC**: Private network with VPC connector for Cloud Run
- **Artifact Registry**: Container image storage
- **Cloud Storage**: File storage bucket
- **Cloud Build**: CI/CD triggers for automated deployments

## Prerequisites

1. **GCP Account** with billing enabled
2. **GCP Project** - Will be created during setup (outty-prod) or use existing project
3. **Terraform** >= 1.0 installed
4. **gcloud CLI** installed and authenticated
5. **Required APIs enabled**:
   ```bash
   gcloud services enable \
     compute.googleapis.com \
     sqladmin.googleapis.com \
     run.googleapis.com \
     vpcaccess.googleapis.com \
     artifactregistry.googleapis.com \
     storage.googleapis.com \
     cloudbuild.googleapis.com \
     servicenetworking.googleapis.com
   ```

## Connecting to GCP via Terminal

### 1. Install gcloud CLI

**macOS (using Homebrew)**:
```bash
brew install google-cloud-sdk
```

**Linux**:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Windows**: Download and run the installer from [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

### 2. Authenticate with GCP

```bash
gcloud auth login
```

This will open a browser window for you to sign in with your GCP account.

### 3. Create GCP Project (if it doesn't exist)

If the `outty-prod` project doesn't exist, create it:

```bash
# Create the project
gcloud projects create outty-prod --name="Outty Production"
```

**Note**: Project IDs must be globally unique. If `outty-prod` is taken, choose a different ID like `outty-prod-XXXXX` and update `terraform.tfvars` accordingly.

Link the project to a billing account:

```bash
# List your billing accounts
gcloud billing accounts list

# Link the project to your billing account (replace BILLING_ACCOUNT_ID)
gcloud billing projects link outty-prod --billing-account=BILLING_ACCOUNT_ID
```

**Important**: You must have a billing account enabled. If you don't have one, create it in the [GCP Console](https://console.cloud.google.com/billing).

### 4. Set Default Project

```bash
gcloud config set project outty-prod
```

### 5. Set Default Region and Zone

```bash
gcloud config set compute/region us-east1
gcloud config set compute/zone us-east1-b
```

### 6. Verify Connection

Check your current configuration:
```bash
gcloud config list
```

Test authentication:
```bash
gcloud auth list
```

Verify project access:
```bash
gcloud projects describe outty-prod
```

### 7. Enable Required APIs

If you haven't already, enable the required APIs:
```bash
gcloud services enable \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  run.googleapis.com \
  vpcaccess.googleapis.com \
  artifactregistry.googleapis.com \
  storage.googleapis.com \
  cloudbuild.googleapis.com \
  servicenetworking.googleapis.com
```

### 8. Application Default Credentials (for Terraform)

Set up Application Default Credentials for Terraform to use:
```bash
gcloud auth application-default login
```

This allows Terraform and other tools to authenticate automatically.

## Setup

### 1. Clone and Configure

```bash
cd outty-infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:
- `database_password`: Strong password for database
- Any other custom values

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Plan

```bash
terraform plan
```

### 4. Apply Configuration

```bash
terraform apply
```

This will create:
- VPC network and subnets
- Cloud SQL MySQL instance
- Cloud Run service
- Bastion VM
- Storage bucket
- Artifact Registry
- Cloud Build triggers

## Configuration

### Variables

Key variables in `terraform.tfvars`:

- `project_id`: GCP project ID (default: "outty-prod")
- `region`: GCP region (default: "us-east1")
- `zone`: GCP zone (default: "us-east1-b")
- `database_password`: Database password (required)
- `cloud_run_min_instances`: Minimum Cloud Run instances (default: 0)
- `cloud_run_max_instances`: Maximum Cloud Run instances (default: 2)

### Outputs

After deployment, get important values:

```bash
# Cloud Run service URL
terraform output cloud_run_service_url

# Database connection name
terraform output cloud_sql_instance_connection_name

# Bastion SSH command
terraform output bastion_ssh_command

# Storage bucket name
terraform output storage_bucket_name
```

## Usage

### Accessing the Database via Bastion

1. **SSH to Bastion**:
   ```bash
   gcloud compute ssh outty-prod-bastion --zone=us-east1-b --project=outty-prod
   ```

2. **Connect to MySQL**:
   ```bash
   mysql -h 127.0.0.1 -P 3306 -u outty_user -p outty_db
   ```

   The Cloud SQL Proxy is running on port 3306 and connects to Cloud SQL via private IP.

### Running Database Migrations

1. SSH to bastion (see above)
2. Copy migration files to bastion
3. Run migrations:
   ```bash
   mysql -h 127.0.0.1 -P 3306 -u outty_user -p outty_db < migration.sql
   ```

### Deploying Application

#### Manual Deployment

1. **Build and push image**:
   ```bash
   cd ../outty-backend
   docker build -t us-east1-docker.pkg.dev/outty-prod/outty-prod-repo/outty-backend:latest .
   docker push us-east1-docker.pkg.dev/outty-prod/outty-prod-repo/outty-backend:latest
   ```

2. **Deploy to Cloud Run**:
   ```bash
   gcloud run deploy outty-backend \
     --image us-east1-docker.pkg.dev/outty-prod/outty-prod-repo/outty-backend:latest \
     --region us-east1 \
     --platform managed \
     --vpc-connector outty-prod-vpc-connector \
     --vpc-egress private-ranges-only
   ```

#### Automated Deployment via Cloud Build

Cloud Build triggers are automatically created via Terraform when GitHub variables are configured:
- **prod-release-trigger**: Builds and pushes Docker image to Artifact Registry (can be run manually with `_VERSION` input)
- **prod-deploy-trigger**: Deploys Docker image from Artifact Registry to Cloud Run (can be run manually with `_VERSION` input, default: latest)

**Setup Steps:**

1. **Connect GitHub Repository to GCP Cloud Build** (REQUIRED - must be done first):

   **Option A: Via GCP Console (Recommended):**
   - Go to [Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers?project=outty-prod)
   - Click "Connect Repository" button (top of the page)
   - Select "GitHub (Cloud Build GitHub App)" or "GitHub"
   - Authenticate with GitHub and grant permissions
   - Select your repository: `outty-backend`
   - Choose installation location: `All repositories` or `Only select repositories`
   - Click "Connect"
   - **Important**: Wait for the connection to complete. You should see your repository listed under "Connected repositories"

   **Option B: Via gcloud CLI:**
   ```bash
   # Create GitHub connection (interactive - will prompt for authentication)
   gcloud builds connections create github \
     --project=outty-prod \
     --region=global \
     --connection=github-connection
   
   # Create repository connection
   gcloud builds connections create github \
     --project=outty-prod \
     --region=global \
     --repository=outty-backend \
     --remote-uri=https://github.com/murilofuga/outty-backend
   ```
   
   **Verify connection:**
   ```bash
   gcloud builds connections list --project=outty-prod --region=global
   ```

2. **Add GitHub Variables to `terraform.tfvars`**:
   ```hcl
   github_owner = "your-username"  # or your organization name (e.g., "murilofuga")
   github_repo  = "outty-backend"
   ```

3. **Apply Terraform**:
   ```bash
   terraform apply
   ```

**Troubleshooting:**

If you get `Error 400: Request contains an invalid argument`:
- **Verify the repository is connected**: Go to Cloud Build Triggers page and check "Connected repositories" section
- **Verify GitHub variables**: Ensure `github_owner` and `github_repo` in `terraform.tfvars` match exactly (case-sensitive)
- **Check repository name**: The repository name should be just the repo name (e.g., `outty-backend`), not the full path

The triggers will be created and linked to your GitHub repository. You can run them manually from the GCP Console by:
- Going to Cloud Build Triggers
- Clicking "Run" on the trigger
- Overriding the `_VERSION` substitution variable if needed

### DNS Configuration

See `modules/dns/README.md` for Namecheap DNS setup instructions.

## Cost Estimation

Monthly costs (approximate):

- Cloud SQL db-f1-micro: ~$7-10
- Cloud Run (1 vCPU, 1GB, min 0): ~$5-20 (depends on traffic, $0 when idle)
- Bastion e2-micro: ~$6
- Cloud Storage: ~$1-5
- Artifact Registry: ~$1-3
- Cloud Build: ~$1-5
- VPC Connector: ~$0-10
- **Total: ~$21-54/month** (low traffic)
- **Minimum: ~$14/month** (no traffic)

## Security

- Cloud SQL uses private IP only (no public exposure)
- VPC firewall rules restrict access
- Service accounts with least privilege
- Cloud Run requires authentication
- Bastion access via SSH keys or IAP

**Important**: Store sensitive values (database passwords, etc.) in Google Secret Manager for production.

## Troubleshooting

### Cloud Run can't connect to Cloud SQL

1. Verify VPC connector is running:
   ```bash
   gcloud compute networks vpc-access connectors list --region=us-east1
   ```

2. Check Cloud Run service account has `cloudsql.client` role

3. Verify Cloud SQL instance has private IP enabled

### Bastion can't connect to Cloud SQL

1. Check Cloud SQL Proxy service:
   ```bash
   sudo systemctl status cloud-sql-proxy
   ```

2. Verify bastion service account has `cloudsql.client` role

3. Check firewall rules allow traffic on port 3306

### Database connection issues

1. Verify database credentials in Cloud Run environment variables
2. Check Cloud SQL instance is running
3. Verify network connectivity via VPC connector

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all infrastructure including the database. Ensure you have backups!

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [VPC Connector Documentation](https://cloud.google.com/vpc/docs/configure-serverless-vpc-access)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)

