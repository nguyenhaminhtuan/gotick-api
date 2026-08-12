output "id" {
  value = google_secret_manager_secret.this.id

  depends_on = [
    google_secret_manager_secret_version.this,
    google_secret_manager_secret_iam_member.accessor,
  ]
}

output "secret_id" {
  value = google_secret_manager_secret.this.secret_id

  depends_on = [
    google_secret_manager_secret_version.this,
    google_secret_manager_secret_iam_member.accessor,
  ]
}
