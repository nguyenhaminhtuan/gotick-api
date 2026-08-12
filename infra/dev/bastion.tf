module "bastion" {
  source = "../modules/bastion"

  project_id            = var.project_id
  name                  = "bastion-${local.env_code}"
  zone                  = "${var.region}-a"
  region                = var.region
  network               = module.network.id
  subnetwork            = module.network.subnets[local.subnet_internal].id
  service_account_email = local.sa_email["bastion"]

  spot     = true
  schedule = null
}

resource "google_iap_tunnel_instance_iam_member" "bastion" {
  for_each = toset(concat(var.developers, [local.sa_member["gha-infra"]]))

  project  = var.project_id
  zone     = "${var.region}-a"
  instance = module.bastion.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value
}
