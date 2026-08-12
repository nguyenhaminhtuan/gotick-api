module "load_balancer" {
  source = "../modules/load-balancer"

  project_id = var.project_id
  name       = local.load_balancer
  region     = var.region

  backends = {
    "${local.load_balancer}-primary" = {
      url_mask = "<service>.${var.domain}"
      logging  = true
    }

    "${local.load_balancer}-preview" = {
      url_mask = "<tag>-<service>.preview.${var.domain}"
      hosts    = ["*.preview.${var.domain}"]
    }
  }

  certificate_domains = [
    var.domain,
    "*.${var.domain}",
    "*.preview.${var.domain}",
  ]
}
