data "google_service_account_access_token" "db_admin" {
  count = local.db_provision

  target_service_account = local.sa_email["db-admin"]
  scopes                 = ["https://www.googleapis.com/auth/sqlservice.login"]
  lifetime               = "1200s"
}

provider "postgresql" {
  host      = "127.0.0.1"
  port      = 5432
  database  = local.db_name
  username  = "sa-db-admin@${var.project_id}.iam"
  password  = one(data.google_service_account_access_token.db_admin[*].access_token)
  sslmode   = "require"
  superuser = false
}

ephemeral "google_secret_manager_secret_version" "migrate" {
  count = local.db_provision

  secret = module.db_migrate_password.secret_id
}

ephemeral "google_secret_manager_secret_version" "app" {
  count = local.db_provision

  secret = module.db_app_password.secret_id
}

resource "postgresql_role" "migrate" {
  count = local.db_provision

  name                = "migrate"
  login               = true
  password_wo         = ephemeral.google_secret_manager_secret_version.migrate[0].secret_data
  password_wo_version = local.db_password_version.migrate
}

resource "postgresql_role" "app" {
  count = local.db_provision

  name                = "app"
  login               = true
  password_wo         = ephemeral.google_secret_manager_secret_version.app[0].secret_data
  password_wo_version = local.db_password_version.app
}

resource "postgresql_schema" "app" {
  count = local.db_provision

  name     = local.db_schema
  database = local.db_name
  owner    = postgresql_role.migrate[0].name

  if_not_exists = true
  drop_cascade  = false
}

resource "postgresql_grant" "migrate_schema" {
  count = local.db_provision

  role        = postgresql_role.migrate[0].name
  database    = local.db_name
  schema      = postgresql_schema.app[0].name
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "migrate_public_schema" {
  count = local.db_provision

  role        = postgresql_role.migrate[0].name
  database    = local.db_name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "app_tables" {
  count = local.db_provision

  role        = postgresql_role.app[0].name
  database    = local.db_name
  schema      = postgresql_schema.app[0].name
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "app_sequences" {
  count = local.db_provision

  role        = postgresql_role.app[0].name
  database    = local.db_name
  schema      = postgresql_schema.app[0].name
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}

resource "postgresql_default_privileges" "app_tables" {
  count = local.db_provision

  role     = postgresql_role.app[0].name
  database = local.db_name
  schema   = postgresql_schema.app[0].name
  owner    = postgresql_role.migrate[0].name

  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_default_privileges" "app_sequences" {
  count = local.db_provision

  role     = postgresql_role.app[0].name
  database = local.db_name
  schema   = postgresql_schema.app[0].name
  owner    = postgresql_role.migrate[0].name

  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}
