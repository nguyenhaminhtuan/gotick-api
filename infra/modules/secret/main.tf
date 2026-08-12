resource "google_secret_manager_secret" "this" {
  project             = var.project_id
  secret_id           = var.secret_id
  deletion_protection = var.deletion_protection

  dynamic "topics" {
    for_each = var.topics

    content {
      name = topics.value
    }
  }

  dynamic "rotation" {
    for_each = var.rotation == null ? [] : [var.rotation]

    content {
      next_rotation_time = coalesce(rotation.value.next_rotation_time, timeadd(plantimestamp(), "24h"))
      rotation_period    = rotation.value.rotation_period
    }
  }

  replication {
    dynamic "auto" {
      for_each = var.replica_locations == null ? [1] : []
      content {}
    }

    dynamic "user_managed" {
      for_each = var.replica_locations == null ? [] : [1]

      content {
        dynamic "replicas" {
          for_each = var.replica_locations

          content {
            location = replicas.value
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [rotation[0].next_rotation_time]
  }
}

resource "google_secret_manager_secret_version" "this" {
  count = var.secret_version == null ? 0 : 1

  secret                 = google_secret_manager_secret.this.id
  secret_data_wo         = var.secret_data
  secret_data_wo_version = var.secret_version
  deletion_policy        = var.version_deletion_policy
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = toset(var.accessors)

  project   = google_secret_manager_secret.this.project
  secret_id = google_secret_manager_secret.this.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}
