ephemeral "random_password" "db_migrate" {
  length  = 32
  special = false
}

ephemeral "random_password" "db_app" {
  length  = 32
  special = false
}

ephemeral "random_password" "db_root" {
  length  = 32
  special = false
}

module "db_app_password" {
  source = "../modules/secret"

  project_id     = var.project_id
  secret_id      = "db-password-app"
  secret_data    = ephemeral.random_password.db_app.result
  secret_version = local.db_password_version.app
  accessors = [
    local.sa_member["api"],
    local.sa_member["asset-cleaner"]
  ]

  deletion_protection = var.deletion_protection
}

module "db_migrate_password" {
  source = "../modules/secret"

  project_id     = var.project_id
  secret_id      = "db-password-migrate"
  secret_data    = ephemeral.random_password.db_migrate.result
  secret_version = local.db_password_version.migrate
  accessors      = [local.sa_member["migrate"]]

  deletion_protection = var.deletion_protection
}

module "db_root_password" {
  source = "../modules/secret"

  project_id     = var.project_id
  secret_id      = "db-password-postgres"
  secret_data    = ephemeral.random_password.db_root.result
  secret_version = local.db_password_version.postgres
  accessors      = []

  deletion_protection = var.deletion_protection
}
