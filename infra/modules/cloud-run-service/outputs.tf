output "name" {
  value = google_cloud_run_v2_service.this.name
}

output "id" {
  value = google_cloud_run_v2_service.this.id
}

output "uri" {
  description = "run.app URL."
  value       = google_cloud_run_v2_service.this.uri
}
