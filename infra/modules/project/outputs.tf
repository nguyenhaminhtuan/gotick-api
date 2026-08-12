output "project_id" {
  description = "Every resource in the project hangs off this, and the dependency below is what puts them all after their APIs."
  value       = google_project.this.project_id
  depends_on  = [google_project_service.this]
}

output "number" {
  description = "Project number, needed by IAM principals and some resource names."
  value       = google_project.this.number

  depends_on = [google_project_service.this]
}

output "name" {
  value = google_project.this.name
}
