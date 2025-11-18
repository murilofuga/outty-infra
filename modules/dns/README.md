# DNS Configuration for Namecheap

This guide explains how to configure DNS records in Namecheap to point to your Cloud Run service.

## Prerequisites

1. Cloud Run service deployed and running
2. Cloud Run service URL (available in Terraform outputs)
3. Access to Namecheap DNS management

## Steps

### Option 1: Using Cloud Run Service URL (Recommended for Testing)

Cloud Run provides a stable service URL in the format:
```
https://SERVICE_NAME-HASH-REGION.a.run.app
```

You can find this URL in the Terraform outputs after deployment:
```bash
terraform output cloud_run_service_url
```

**For Namecheap:**
1. Log in to Namecheap
2. Go to Domain List → Manage → Advanced DNS
3. Add an A record:
   - Type: A
   - Host: `api` (or `@` for root domain)
   - Value: [Get the IP from Cloud Run service URL using `nslookup` or `dig`]
   - TTL: Automatic (or 300)

**Note:** Cloud Run service URLs use Google's load balancer IPs which may change. For production, use Option 2.

### Option 2: Using Cloud Load Balancer (Recommended for Production)

For a stable IP address and custom domain support, you'll need to set up a Cloud Load Balancer:

1. **Create a Serverless NEG (Network Endpoint Group)**
2. **Create a Backend Service** pointing to the NEG
3. **Create a URL Map** for routing
4. **Create a Target HTTPS Proxy**
5. **Create a Global Forwarding Rule** with a static IP
6. **Configure SSL Certificate** (managed or self-signed)

Then in Namecheap:
1. Add an A record pointing to the static IP from the forwarding rule
2. Or add a CNAME record pointing to the load balancer's hostname

### Quick Setup Script

After Terraform deployment, run:
```bash
# Get Cloud Run service URL
SERVICE_URL=$(terraform output -raw cloud_run_service_url)

# Extract hostname
HOSTNAME=$(echo $SERVICE_URL | sed 's|https://||')

# Get IP address
IP=$(dig +short $HOSTNAME | head -n 1)

echo "Add this A record in Namecheap:"
echo "Host: api"
echo "Value: $IP"
echo "TTL: 300"
```

## SSL Certificate

For HTTPS with custom domain:
1. Use Google-managed SSL certificate (recommended)
2. Or upload your own certificate to Cloud Load Balancer

## Example Namecheap DNS Records

```
Type    Host    Value                    TTL
A       api     35.xxx.xxx.xxx           300
CNAME   www     api.outty.app            300
```

## Verification

After DNS propagation (usually 5-30 minutes):
```bash
# Check DNS resolution
dig api.outty.app

# Test HTTPS endpoint
curl https://api.outty.app/actuator/health
```

## Troubleshooting

- **DNS not resolving**: Wait for propagation (up to 48 hours, usually much faster)
- **SSL errors**: Ensure SSL certificate is configured and valid
- **502 errors**: Check Cloud Run service is running and healthy
- **Connection refused**: Verify firewall rules and VPC connector configuration

