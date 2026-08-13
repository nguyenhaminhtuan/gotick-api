locals {
  repo = "${var.github_owner}/${var.github_repo}"

  environment_bindings = flatten([
    for environment, ids in var.environment_service_account_ids : [
      for id in ids : { environment = environment, service_account_id = id }
    ]
  ])
}

resource "google_iam_workload_identity_pool" "this" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.display_name
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
    # Present only on tokens minted for a job that declares an environment,
    # which is what makes environment-scoped bindings below meaningful.
    "attribute.environment" = "assertion.environment"
  }

  attribute_condition = format("assertion.repository == '%s'", local.repo)
}

# count rather than for_each: an id here is projects/<project>/serviceAccounts/…,
# and the project does not exist until apply.
resource "google_service_account_iam_member" "impersonate" {
  count = length(var.service_account_ids)

  service_account_id = var.service_account_ids[count.index]
  role               = "roles/iam.workloadIdentityUser"
  member = format(
    "principalSet://iam.googleapis.com/%s/attribute.repository/%s",
    google_iam_workload_identity_pool.this.name,
    local.repo,
  )
}

# Narrower than the binding above: the token carries an environment claim only
# once the job has cleared that environment's protection rules, so a workflow on
# any other branch cannot reach these accounts.
resource "google_service_account_iam_member" "impersonate_from_environment" {
  count = length(local.environment_bindings)

  service_account_id = local.environment_bindings[count.index].service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member = format(
    "principalSet://iam.googleapis.com/%s/attribute.environment/%s",
    google_iam_workload_identity_pool.this.name,
    local.environment_bindings[count.index].environment,
  )
}
