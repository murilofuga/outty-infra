# DNS Configuration for Namecheap - Custom Domain Setup

This guide explains how to configure DNS records in Namecheap for the custom domain `api.outty.app` using Cloud Run domain mapping.

## Overview

The DNS module uses `google_cloud_run_domain_mapping` to automatically:
- Map `api.outty.app` to your Cloud Run service
- Provision a Google-managed SSL certificate
- Generate DNS records that need to be added to Namecheap

## Prerequisites

1. Cloud Run service deployed and running
2. Domain `outty.app` registered in Namecheap
3. Access to Namecheap DNS management
4. Terraform applied (domain mapping created)

## Setup Steps

### Step 1: Apply Terraform

The DNS module is automatically included when you run `terraform apply`. This creates the domain mapping resource:

```bash
cd outty-infra
terraform apply
```

### Step 2: Get DNS Records from Terraform Output

After Terraform applies successfully, get the DNS records that need to be added to Namecheap:

```bash
# View all DNS records
terraform output dns_records

# View custom domain URL
terraform output custom_domain_url

# Check domain status
terraform output domain_mapping_status
terraform output domain_ready
```

The `dns_records` output will show the DNS records in this format:
```
{
  "A" = {
    name   = "api.outty.app"
    type   = "A"
    rrdata = "xxx.xxx.xxx.xxx"
  }
  "CNAME" = {
    name   = "api.outty.app"
    type   = "CNAME"
    rrdata = "ghs.googlehosted.com."
  }
}
```

### Step 3: Add DNS Records to Namecheap

1. **Log in to Namecheap**
   - Go to [Namecheap](https://www.namecheap.com/)
   - Sign in to your account

2. **Navigate to DNS Management**
   - Go to **Domain List** → Select `outty.app` → Click **Manage**
   - Click on the **Advanced DNS** tab

3. **Add the DNS Records**

   For each record in the Terraform output, add it to Namecheap:

   **For A record:**
   - Click **Add New Record**
   - Type: `A Record`
   - Host: `api` (or `@` if it's the root domain)
   - Value: The IP address from `rrdata` (e.g., `xxx.xxx.xxx.xxx`)
   - TTL: `Automatic` (or `300`)

   **For CNAME record (if present):**
   - Click **Add New Record**
   - Type: `CNAME Record`
   - Host: `api`
   - Value: The CNAME value from `rrdata` (e.g., `ghs.googlehosted.com.`)
   - TTL: `Automatic` (or `300`)

   **Important:** Remove the trailing dot (`.`) from CNAME values if Namecheap adds it automatically.

4. **Save Changes**
   - Click the checkmark to save each record
   - Wait for DNS propagation (usually 5-30 minutes, can take up to 48 hours)

### Step 4: Verify Domain Mapping Status

After adding DNS records, check the domain mapping status:

```bash
# Check if domain is ready
terraform output domain_ready

# View detailed status
terraform output domain_mapping_status
```

You can also check in the GCP Console:
- Go to **Cloud Run** → **Domain Mappings**
- Look for `api.outty.app`
- Status should change from "Pending" to "Active" after DNS propagation

### Step 5: Verify SSL Certificate

Google automatically provisions an SSL certificate once DNS is verified. This typically takes 15-60 minutes after DNS propagation.

Check certificate status:
```bash
gcloud run domain-mappings describe api.outty.app \
  --region=us-east1 \
  --project=outty-prod \
  --format="value(status.conditions)"
```

## Verification

After DNS propagation and SSL certificate provisioning:

```bash
# Check DNS resolution
dig api.outty.app

# Test HTTPS endpoint
curl https://api.outty.app/actuator/health

# Test with authentication
curl -X GET https://api.outty.app/api/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Expected Timeline

1. **Terraform apply**: ~2-5 minutes (creates domain mapping)
2. **DNS propagation**: 5-30 minutes (usually), up to 48 hours (worst case)
3. **SSL certificate provisioning**: 15-60 minutes after DNS is verified
4. **Total**: Typically 20-90 minutes, worst case up to 48 hours

## Troubleshooting

### Domain Mapping Shows "Pending" Status

- **Cause**: DNS records not yet added or not propagated
- **Solution**: 
  1. Verify DNS records are correctly added in Namecheap
  2. Wait for DNS propagation (check with `dig api.outty.app`)
  3. Ensure TTL is set correctly (lower TTL = faster propagation)

### SSL Certificate Not Provisioned

- **Cause**: DNS not fully propagated or incorrect DNS records
- **Solution**:
  1. Verify DNS records match exactly what Terraform output shows
  2. Check DNS propagation: `dig api.outty.app`
  3. Wait up to 60 minutes after DNS is verified
  4. Check GCP Console for certificate status

### 502 Bad Gateway Errors

- **Cause**: Cloud Run service not running or unhealthy
- **Solution**:
  1. Check Cloud Run service status: `gcloud run services describe outty-backend --region=us-east1`
  2. Check service logs for errors
  3. Verify startup probe is passing

### DNS Not Resolving

- **Cause**: DNS records not added or incorrect
- **Solution**:
  1. Double-check DNS records in Namecheap match Terraform output
  2. Verify no typos in host or value fields
  3. Wait for DNS propagation (can take up to 48 hours)
  4. Use `dig api.outty.app` to check resolution

### Connection Refused

- **Cause**: Firewall rules or VPC connector issues
- **Solution**:
  1. Verify Cloud Run service is accessible via default URL
  2. Check VPC connector is working
  3. Verify firewall rules allow traffic

## Manual DNS Record Lookup

If you need to manually get DNS records from GCP:

```bash
gcloud run domain-mappings describe api.outty.app \
  --region=us-east1 \
  --project=outty-prod \
  --format="value(status.resourceRecords)"
```

## Additional Resources

- [Cloud Run Custom Domains Documentation](https://cloud.google.com/run/docs/mapping-custom-domains)
- [Namecheap DNS Management Guide](https://www.namecheap.com/support/knowledgebase/article.aspx/767/10/how-to-change-dns-for-a-domain/)
- [DNS Propagation Checker](https://www.whatsmydns.net/)
