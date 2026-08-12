output "projects" {
  description = "project_id of each env, for the project_id variable of infra/<env>."
  value       = { for env, project in module.env_project : env => project.project_id }
}

output "env_state_buckets" {
  description = "Backend bucket of each env, for backend.hcl of infra/<env>."
  value       = { for env, bucket in module.env_state_bucket : env => bucket.name }
}

output "seed_state_bucket" {
  description = "Backend bucket of this stack itself."
  value       = module.seed_bucket_state.name
}
