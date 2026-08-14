module "database" {
  source = "../modules/database"

  project_id    = var.project_id
  name          = local.sql_instance
  region        = var.region
  network       = module.network.id
  tier          = "enterprise-plus-2"
  database_name = local.db_name

  peering_range_address       = local.psa_range_address
  peering_range_prefix_length = local.psa_range_prefix_length
  deletion_protection         = var.deletion_protection

  activation_policy = "ALWAYS"
  high_availability = true

  maintenance_window = {
    day          = "tuesday"
    hour         = 20
    update_track = "stable"
  }

  read_pool = { node_count = 1 }

  connection_pool = {
    flags = {
      pool_mode     = "transaction"
      max_pool_size = "100"
    }
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

  query_insights = {}
}
