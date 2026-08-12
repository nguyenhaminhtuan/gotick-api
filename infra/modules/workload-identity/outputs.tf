output "provider_name" {
  description = "Value for the workload_identity_provider input of google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "pool_name" {
  value = google_iam_workload_identity_pool.this.name
}
