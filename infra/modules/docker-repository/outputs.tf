output "repository_id" {
  value = google_artifact_registry_repository.this.repository_id
}

output "url" {
  description = "Image path prefix, e.g. REGION-docker.pkg.dev/PROJECT/REPOSITORY."
  value = format(
    "%s-docker.pkg.dev/%s/%s",
    var.region,
    var.project_id,
    google_artifact_registry_repository.this.repository_id,
  )
}

output "docker_registry" {
  description = "Host to pass to gcloud auth configure-docker."
  value       = "${var.region}-docker.pkg.dev"
}
