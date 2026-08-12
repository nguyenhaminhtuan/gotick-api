resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = var.description

  dynamic "cleanup_policies" {
    for_each = var.untagged_retention_days == null ? [] : [1]

    content {
      id     = "delete-untagged"
      action = "DELETE"

      condition {
        tag_state  = "UNTAGGED"
        older_than = format("%dh", var.untagged_retention_days * 24)
      }
    }
  }

  dynamic "cleanup_policies" {
    for_each = var.tagged_keep_count == null ? [] : [1]

    content {
      id     = "keep-tagged"
      action = "KEEP"

      most_recent_versions {
        keep_count = var.tagged_keep_count
      }
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "writer" {
  for_each = toset(var.writer_members)

  project    = google_artifact_registry_repository.this.project
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.writer"
  member     = each.value
}

resource "google_artifact_registry_repository_iam_member" "reader" {
  for_each = toset(var.reader_members)

  project    = google_artifact_registry_repository.this.project
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}
