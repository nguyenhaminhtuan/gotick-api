locals {
  runtime_service_accounts = {
    "api" = {
      display_name    = "Cloud Run api"
      project_roles   = ["roles/firebaseauth.admin"]
      deployed_by_gha = true
      envs            = ["dev", "prd"]
    }

    "docs" = {
      display_name    = "Cloud Run docs"
      project_roles   = []
      deployed_by_gha = true
      envs            = ["dev"]
    }

    "migrate" = {
      display_name    = "Cloud Run job migrate"
      project_roles   = []
      deployed_by_gha = true
      envs            = ["dev", "prd"]
    }

    "asset-cleaner" = {
      display_name    = "Cloud Run job asset-cleaner"
      project_roles   = []
      deployed_by_gha = true
      envs            = ["dev", "prd"]
    }

    "scheduler" = {
      display_name    = "Cloud Scheduler"
      project_roles   = []
      deployed_by_gha = false
      envs            = ["dev", "prd"]
    }
  }

  env_service_accounts = {
    for pair in flatten([
      for name, account in local.runtime_service_accounts : [
        for env in account.envs : { env = env, name = name, account = account }
      ]
    ]) : "${pair.env}/${pair.name}" => pair
  }
}

module "gha_infra_sa" {
  source = "../modules/service-account"

  for_each     = local.env
  project_id   = module.env_project[each.key].project_id
  account_id   = "sa-gha-infra"
  display_name = "GitHub Actions infrastructure"
  description  = "Impersonated by ${var.github_owner}/${var.github_repo} through Workload Identity Federation"

  project_roles = each.value.infra_project_roles

  token_creators = var.developers
}

module "gha_deployer_sa" {
  source = "../modules/service-account"

  for_each     = local.env
  project_id   = module.env_project[each.key].project_id
  account_id   = "sa-gha-deployer"
  display_name = "GitHub Actions deployer"
  description  = "Impersonated by ${var.github_owner}/${var.github_repo} through Workload Identity Federation"

  project_roles = ["roles/run.developer"]
}

module "runtime_sa" {
  source = "../modules/service-account"

  for_each     = local.env_service_accounts
  project_id   = module.env_project[each.value.env].project_id
  account_id   = "sa-${each.value.name}"
  display_name = each.value.account.display_name

  project_roles = each.value.account.project_roles

  user_members = concat(
    [module.gha_infra_sa[each.value.env].member],
    each.value.account.deployed_by_gha ? [module.gha_deployer_sa[each.value.env].member] : [],
  )
}

module "bastion_sa" {
  source = "../modules/service-account"

  for_each     = local.env
  project_id   = module.env_project[each.key].project_id
  account_id   = "sa-bastion"
  display_name = "Bastion host"

  project_roles = []

  user_members = concat(
    [module.gha_infra_sa[each.key].member],
    var.developers
  )
}

module "db_admin_sa" {
  source = "../modules/service-account"

  for_each      = local.env
  project_id    = module.env_project[each.key].project_id
  account_id    = "sa-db-admin"
  display_name  = "Terraform postgresql provider"
  project_roles = ["roles/cloudsql.instanceUser"]

  token_creators = concat(
    var.developers,
    [module.gha_infra_sa[each.key].member]
  )
}

resource "google_project_iam_member" "operators_os_login" {
  for_each = {
    for pair in setproduct(keys(local.env), var.developers) :
    "${pair[0]}/${pair[1]}" => { env = pair[0], member = pair[1] }
  }

  project = module.env_project[each.value.env].project_id
  role    = "roles/compute.osLogin"
  member  = each.value.member
}

# Separate from the operators' binding above: the member here is only known after
# apply, so it cannot take part in a for_each key.
resource "google_project_iam_member" "gha_infra_os_login" {
  for_each = local.env

  project = module.env_project[each.key].project_id
  role    = "roles/compute.osLogin"
  member  = module.gha_infra_sa[each.key].member
}

resource "random_id" "wif" {
  byte_length = 2
}

module "github_oidc" {
  source = "../modules/workload-identity"

  for_each     = local.env
  project_id   = module.env_project[each.key].project_id
  github_owner = var.github_owner
  github_repo  = var.github_repo
  pool_id      = "pool-${each.key}-github-${random_id.wif.hex}"

  # Terraform runs outside any GitHub environment, so it stays repository-scoped.
  service_account_ids = [module.gha_infra_sa[each.key].id]

  # The deployer is reachable only from the GitHub environment of the same name,
  # so a run that has not cleared that environment's protection rules cannot
  # deploy with it.
  environment_service_account_ids = {
    (each.key) = [module.gha_deployer_sa[each.key].id]
  }
}
