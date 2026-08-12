module "network" {
  source = "../modules/network"

  project_id = var.project_id
  name       = local.vpc
  region     = var.region

  subnets = {
    (local.subnet_run) = {
      ip_cidr_range            = "10.30.0.0/20"
      private_ip_google_access = true
    }

    (local.subnet_internal) = {
      ip_cidr_range            = "10.10.0.0/24"
      private_ip_google_access = true
    }
  }

  firewall_rules = {
    "fw-${local.env_code}-allow-ingress-iap-ssh" = {
      description = "SSH from the IAP TCP forwarding range, which is the only way into the bastion."
      direction   = "INGRESS"
      ranges      = ["35.235.240.0/20"]
      protocols   = { tcp = ["22"] }
      priority    = 1000

      target_service_accounts = [local.sa_email["bastion"]]
    }
  }
}
