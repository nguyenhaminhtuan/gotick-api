terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "random_id" "suffix" {
  count = var.random_suffix ? 1 : 0

  byte_length = 2
}

locals {
  suffix = var.random_suffix ? random_id.suffix[0].hex : var.suffix
  name   = local.suffix == null ? var.name : "${var.name}-${local.suffix}"
}

resource "google_storage_bucket" "this" {
  name     = local.name
  project  = var.project_id
  location = var.location

  force_destroy = var.force_destroy

  versioning {
    enabled = var.versioning
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  dynamic "cors" {
    for_each = var.cors

    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = cors.value.response_headers
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_age_days == null ? [] : [1]

    content {
      condition {
        age = var.lifecycle_age_days
      }
      action {
        type = "Delete"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.keep_versions == null ? [] : [1]

    content {
      condition {
        num_newer_versions = var.keep_versions
      }
      action {
        type = "Delete"
      }
    }
  }
}

resource "google_storage_bucket_iam_member" "object_admin" {
  for_each = toset(var.object_admins)

  bucket = google_storage_bucket.this.name
  role   = "roles/storage.objectAdmin"
  member = each.value
}

resource "google_storage_bucket_iam_member" "object_viewer" {
  for_each = toset(var.object_viewers)

  bucket = google_storage_bucket.this.name
  role   = "roles/storage.objectViewer"
  member = each.value
}
