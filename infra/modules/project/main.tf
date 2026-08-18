terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
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
  suffix     = var.random_suffix ? random_id.suffix[0].hex : var.suffix
  project_id = local.suffix == null ? var.project_id : "${var.project_id}-${local.suffix}"
}

resource "google_project" "this" {
  project_id      = local.project_id
  name            = var.name
  org_id          = var.org_id
  folder_id       = var.folder_id
  billing_account = var.billing_account

  auto_create_network = var.auto_create_network
  deletion_policy     = var.deletion_policy
  labels              = local.labels
}

locals {
  services = toset(concat(
    var.services,
    var.enable_firebase ? ["firebase.googleapis.com"] : [],
  ))

  labels = merge(
    var.labels,
    var.enable_firebase ? { firebase = "enabled" } : {},
  )
}

resource "google_project_service" "this" {
  for_each = local.services

  project = google_project.this.project_id
  service = each.value

  disable_on_destroy = var.disable_services_on_destroy
}

resource "google_firebase_project" "this" {
  count = var.enable_firebase ? 1 : 0

  provider = google-beta
  project  = google_project.this.project_id

  depends_on = [google_project_service.this]
}
