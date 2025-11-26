output "domain_url" {
  description = "Custom domain URL (HTTPS via load balancer)"
  value       = "https://${var.domain}"
}

output "dns_records" {
  description = "DNS A record that needs to be added to your DNS provider (e.g., Namecheap)"
  value = {
    type   = "A"
    name   = var.domain
    value  = var.load_balancer_ip
    ttl    = 300
    note   = "Point your domain to the load balancer IP address"
  }
}

output "load_balancer_ip" {
  description = "Load balancer IP address for DNS configuration"
  value       = var.load_balancer_ip
}

