output "load_balancer_ip_address" {
  description = "A record for <domain>, api.<domain> and *.preview.<domain>."
  value       = module.load_balancer.ip_address
}

output "db_private_ip" {
  description = "Far end of the port forward when running infra/postgres through the bastion."
  value       = module.database.private_ip_address
}

output "bastion_zone" {
  description = "For gcloud compute ssh --zone."
  value       = module.bastion.zone
}

output "dns_authorization_records" {
  description = "CNAMEs to create before the certificate can be issued. It stays in provisioning until each one resolves."
  value       = module.load_balancer.dns_authorization_records
}
