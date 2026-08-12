terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

# The agent IAP calls the backend as. Created here rather than by the caller,
# because it is only ever needed by a backend service that has IAP switched on.
resource "google_project_service_identity" "iap" {
  count    = var.iap == null ? 0 : 1
  provider = google-beta

  project = var.project_id
  service = "iap.googleapis.com"
}

locals {
  # The backend with no hosts answers everything the host rules below do not.
  default_backend = one([for k, b in var.backends : k if length(b.hosts) == 0])
  host_backends   = { for k, b in var.backends : k => b if length(b.hosts) > 0 }

  authorization_domains = toset([for d in var.certificate_domains : trimprefix(d, "*.")])

  # Resource names cannot hold a dot or an asterisk.
  iap_members = {
    for pair in flatten([
      for k, b in var.backends : [
        for m in(b.iap == null ? [] : b.iap.members) : { backend = k, member = m }
      ]
    ]) : "${pair.backend}/${pair.member}" => pair
  }

  certificate_hostnames = {
    for d in var.certificate_domains :
    replace(replace(d, "*.", "wildcard-"), ".", "-") => d
  }
}

resource "google_compute_global_address" "this" {
  project      = var.project_id
  name         = var.name
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

resource "google_compute_region_network_endpoint_group" "this" {
  for_each = var.backends

  project               = var.project_id
  name                  = each.key
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    url_mask = each.value.url_mask
  }
}

resource "google_compute_backend_service" "this" {
  for_each = var.backends

  project               = var.project_id
  name                  = each.key
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.this[each.key].id
  }

  dynamic "iap" {
    for_each = each.value.iap == null ? [] : [1]

    content {
      enabled              = true
      oauth2_client_id     = var.iap.oauth_client_id
      oauth2_client_secret = var.iap.oauth_client_secret
    }
  }

  dynamic "log_config" {
    for_each = each.value.logging ? [1] : []

    content {
      enable      = true
      sample_rate = each.value.log_sample_rate
    }
  }
}

resource "google_iap_web_backend_service_iam_member" "accessor" {
  for_each = local.iap_members

  project             = var.project_id
  web_backend_service = google_compute_backend_service.this[each.value.backend].name
  role                = "roles/iap.httpsResourceAccessor"
  member              = each.value.member
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
    domains            = var.certificate_domains
    dns_authorizations = [for a in google_certificate_manager_dns_authorization.this : a.id]
  }
}

resource "google_certificate_manager_certificate_map" "this" {
  project = var.project_id
  name    = var.name
}

resource "google_certificate_manager_certificate_map_entry" "this" {
  for_each = local.certificate_hostnames

  project      = var.project_id
  name         = "${var.name}-${each.key}"
  map          = google_certificate_manager_certificate_map.this.name
  certificates = [google_certificate_manager_certificate.this.id]
  hostname     = each.value
}

resource "google_compute_url_map" "https" {
  project         = var.project_id
  name            = var.name
  default_service = google_compute_backend_service.this[local.default_backend].id

  dynamic "host_rule" {
    for_each = local.host_backends

    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = local.host_backends

    content {
      name            = path_matcher.key
      default_service = google_compute_backend_service.this[path_matcher.key].id
    }
  }
}

resource "google_compute_target_https_proxy" "this" {
  project = var.project_id
  name    = var.name
  url_map = google_compute_url_map.https.id

  certificate_map             = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.this.id}"
  http_keep_alive_timeout_sec = var.keep_alive_timeout
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = var.name
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
  ip_address            = google_compute_global_address.this.id
  target                = google_compute_target_https_proxy.this.id
  port_range            = "443"
}

resource "google_compute_url_map" "http_redirect" {
  count = var.http_redirect ? 1 : 0

  project = var.project_id
  name    = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  count = var.http_redirect ? 1 : 0

  project = var.project_id
  name    = "${var.name}-http-redirect"
  url_map = google_compute_url_map.http_redirect[0].id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  count = var.http_redirect ? 1 : 0

  project               = var.project_id
  name                  = "${var.name}-http-redirect"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "PREMIUM"
  ip_address            = google_compute_global_address.this.id
  target                = google_compute_target_http_proxy.redirect[0].id
  port_range            = "80"
}
