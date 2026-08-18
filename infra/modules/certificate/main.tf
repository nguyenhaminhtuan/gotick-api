terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  authorization_domains = toset([for d in var.domains : trimprefix(d, "*.")])

  hostnames = {
    for d in var.domains :
    replace(replace(d, "*.", "wildcard-"), ".", "-") => d
  }
}

resource "google_certificate_manager_dns_authorization" "this" {
  for_each = local.authorization_domains

  project = var.project_id
  name    = "${var.name}-${replace(each.value, ".", "-")}"
  domain  = each.value

  type = "PER_PROJECT_RECORD"
}

resource "google_certificate_manager_certificate" "this" {
  project = var.project_id
  name    = var.name

  managed {
    domains            = var.domains
    dns_authorizations = [for a in google_certificate_manager_dns_authorization.this : a.id]
  }
}

resource "google_certificate_manager_certificate_map" "this" {
  project = var.project_id
  name    = var.name
}

resource "google_certificate_manager_certificate_map_entry" "this" {
  for_each = local.hostnames

  project      = var.project_id
  name         = "${var.name}-${each.key}"
  map          = google_certificate_manager_certificate_map.this.name
  certificates = [google_certificate_manager_certificate.this.id]
  hostname     = each.value
}
