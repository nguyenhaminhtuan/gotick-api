resource "google_compute_global_address" "edge" {
  project      = var.project_id
  name         = local.edge
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

module "certificate" {
  source = "../modules/certificate"

  project_id = var.project_id
  name       = local.edge

  domains = [
    var.domain,
    "*.${var.domain}",
    "*.preview.${var.domain}",
  ]
}

module "load_balancer" {
  count  = 0
  source = "../modules/load-balancer"

  project_id = var.project_id
  name       = local.load_balancer
  region     = var.region

  backends = {
    "${local.load_balancer}-primary" = {
      url_mask = "<service>.${var.domain}"
      logging  = true
    }

    "${local.load_balancer}-docs" = {
      url_mask = "<service>.${var.domain}"
      hosts    = ["docs.${var.domain}"]
      iap      = { members = var.developers }
    }

    "${local.load_balancer}-preview" = {
      url_mask = "<tag>-<service>.preview.${var.domain}"
      hosts    = ["*.preview.${var.domain}"]
    }
  }

  iap = {
    oauth_client_id     = var.iap_oauth_client_id
    oauth_client_secret = var.iap_oauth_client_secret
  }

  certificate_map_id = module.certificate.certificate_map_id
  ip_address         = google_compute_global_address.edge.id
}

