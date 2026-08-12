module "database" {
  source = "../modules/database"

  project_id    = var.project_id
  name          = local.sql_instance
  region        = var.region
  network       = module.network.id
  tier          = "enterprise-small"
  database_name = local.db_name

  peering_range_address       = local.psa_range_address
  peering_range_prefix_length = local.psa_range_prefix_length
  deletion_protection         = var.deletion_protection

  activation_policy = "NEVER"
  high_availability = false

  maintenance_window = {
    day          = "tuesday"
    hour         = 20
    update_track = "canary"
  }

  users = {
    postgres = { password_version = local.db_password_version.postgres }

    "sa-db-admin@${var.project_id}.iam" = {
      type           = "CLOUD_IAM_SERVICE_ACCOUNT"
      database_roles = ["cloudsqlsuperuser"]
    }
  }

  user_passwords = {
    postgres = ephemeral.random_password.db_root.result
  }

  database_flags = {
    "cloudsql.iam_authentication" = "on"
  }
}
