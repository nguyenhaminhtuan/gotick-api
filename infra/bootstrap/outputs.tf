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

output "workload_identity_providers" {
  description = "WIF_PROVIDER variable of the GitHub environment of each env. The pool carries a random suffix, so this is the only way to learn it."
  value       = { for env, oidc in module.github_oidc : env => oidc.provider_name }
}

output "gha_deployer_service_accounts" {
  description = "DEPLOYER_SA variable of the GitHub environment of each env."
  value       = { for env, sa in module.gha_deployer_sa : env => sa.email }
}
