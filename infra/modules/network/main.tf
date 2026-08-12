resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  project       = var.project_id
  name          = each.key
  network       = google_compute_network.this.id
  region        = coalesce(each.value.region, var.region)
  ip_cidr_range = each.value.ip_cidr_range

  private_ip_google_access = each.value.private_ip_google_access
}

resource "google_compute_firewall" "this" {
  for_each = var.firewall_rules

  project     = var.project_id
  network     = google_compute_network.this.name
  name        = each.key
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges      = each.value.direction == "INGRESS" ? each.value.ranges : null
  destination_ranges = each.value.direction == "EGRESS" ? each.value.ranges : null

  target_tags             = each.value.target_tags
  target_service_accounts = each.value.target_service_accounts

  dynamic "allow" {
    for_each = each.value.action == "allow" ? each.value.protocols : {}

    content {
      protocol = allow.key
      ports    = allow.value
    }
  }

  dynamic "deny" {
    for_each = each.value.action == "deny" ? each.value.protocols : {}

    content {
      protocol = deny.key
      ports    = deny.value
    }
  }
}
