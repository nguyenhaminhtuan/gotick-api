output "id" {
  value = google_compute_network.this.id
}

output "name" {
  value = google_compute_network.this.name
}

output "self_link" {
  value = google_compute_network.this.self_link
}

output "subnets" {
  description = "Keyed by subnet name."

  value = {
    for k, s in google_compute_subnetwork.this : k => {
      id            = s.id
      self_link     = s.self_link
      ip_cidr_range = s.ip_cidr_range
      region        = s.region
    }
  }
}
