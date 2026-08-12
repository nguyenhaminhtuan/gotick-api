output "name" {
  value = google_compute_instance.this.name
}

output "zone" {
  value = google_compute_instance.this.zone
}

output "self_link" {
  value = google_compute_instance.this.self_link
}

output "instance_id" {
  description = "For google_iap_tunnel_instance_iam_member."
  value       = google_compute_instance.this.instance_id
}
