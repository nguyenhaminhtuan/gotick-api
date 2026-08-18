output "certificate_map_id" {
  description = "For the certificate_map of a target HTTPS proxy."
  value       = google_certificate_manager_certificate_map.this.id
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
