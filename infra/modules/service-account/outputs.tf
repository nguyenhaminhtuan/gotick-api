locals {
  email = "${var.account_id}@${var.project_id}.iam.gserviceaccount.com"
}

output "email" {
  value      = local.email
  depends_on = [google_service_account.this]
}

output "member" {
  description = "IAM member form, for granting access from other modules."
  value       = "serviceAccount:${local.email}"

  depends_on = [google_service_account.this]
}

output "id" {
  description = "Fully qualified id, for service-account-scoped IAM bindings."
  value       = "projects/${var.project_id}/serviceAccounts/${local.email}"

  depends_on = [google_service_account.this]
}
