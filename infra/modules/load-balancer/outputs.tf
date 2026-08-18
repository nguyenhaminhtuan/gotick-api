output "backend_services" {
  value = { for k, b in google_compute_backend_service.this : k => b.name }
}
