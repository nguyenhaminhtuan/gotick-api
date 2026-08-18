output "name" {
  description = "Resource name of the Identity Platform config."
  value       = google_identity_platform_config.this.name
}

output "google_sign_in_enabled" {
  value = length(google_identity_platform_default_supported_idp_config.google) > 0
}
