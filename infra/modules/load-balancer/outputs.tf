output "ip_address" {
  description = "Point the A record for every certificate domain at this."
  value       = google_compute_global_address.this.address
}

output "dns_authorization_records" {
  description = <<-EOT
    CNAME records to create before the certificate can be issued, keyed by
    domain. The certificate stays in provisioning until each one resolves.
  EOT

  value = {
    for domain, a in google_certificate_manager_dns_authorization.this :
    domain => {
      name = one(a.dns_resource_record).name
      type = one(a.dns_resource_record).type
      data = one(a.dns_resource_record).data
    }
  }
}

output "certificate_map" {
  value = google_certificate_manager_certificate_map.this.name
}

output "backend_services" {
  value = { for k, b in google_compute_backend_service.this : k => b.name }
}
