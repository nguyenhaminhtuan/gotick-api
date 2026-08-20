module "migrate" {
  source = "../modules/cloud-run-job"

  project_id      = var.project_id
  name            = "migrate"
  region          = var.region
  service_account = local.sa_email["migrate"]

  deletion_protection = var.deletion_protection

  parallelism = 1
  task_count  = 1
  timeout     = "600s"

  resource_limits = { cpu = "1", memory = "1Gi" }

  args = ["up"]

  vpc_access = {
    network    = module.network.id
    subnetwork = module.network.subnets[local.subnet_run].id
  }

  env = {
    DB_HOST     = module.database.private_ip_address
    DB_PORT     = "5432"
    DB_NAME     = module.database.database_name
    DB_SCHEMA   = local.db_schema
    DB_USER     = "migrate"
    DB_SSL_MODE = "require"

    GOOSE_MIGRATION_DIR = "/db/migrations"
    GOOSE_TABLE         = "public.migrations"
  }

  secrets = {
    DB_PASSWORD = { secret = module.db_migrate_password.secret_id }
  }
}

module "migrate_background" {
  source = "../modules/cloud-run-job"

  project_id      = var.project_id
  name            = "migrate-background"
  region          = var.region
  service_account = local.sa_email["migrate"]

  deletion_protection = var.deletion_protection

  parallelism = 1
  task_count  = 1
  timeout     = "21600s" # 6h

  resource_limits = { cpu = "1", memory = "1Gi" }

  args = ["up"]

  vpc_access = {
    network    = module.network.id
    subnetwork = module.network.subnets[local.subnet_run].id
  }

  env = {
    DB_HOST     = module.database.private_ip_address
    DB_PORT     = "5432"
    DB_NAME     = module.database.database_name
    DB_SCHEMA   = local.db_schema
    DB_USER     = "migrate"
    DB_SSL_MODE = "require"

    GOOSE_MIGRATION_DIR = "/db/background"
    GOOSE_TABLE         = "public.migrations_background"
  }

  secrets = {
    DB_PASSWORD = { secret = module.db_migrate_password.secret_id }
  }
}

module "migrate_background_schedule" {
  source = "../modules/cloud-scheduler-job"

  project_id      = var.project_id
  name            = "migrate-background"
  region          = var.region
  job_name        = module.migrate_background.name
  service_account = local.sa_email["scheduler"]

  description = "Runs the background migration stream."

  schedule  = "0 2 * * *"
  time_zone = local.scheduler_timezone

  paused = true
}

module "asset_cleaner" {
  source = "../modules/cloud-run-job"

  project_id      = var.project_id
  name            = "asset-cleaner"
  region          = var.region
  service_account = local.sa_email["asset-cleaner"]

  deletion_protection = var.deletion_protection

  parallelism = 1
  task_count  = 1
  timeout     = "900s"

  resource_limits = { cpu = "1", memory = "1Gi" }

  vpc_access = {
    network    = module.network.id
    subnetwork = module.network.subnets[local.subnet_run].id
    egress     = "all-traffic"
  }

  env = {
    DB_HOST       = module.database.private_ip_address
    DB_PORT       = "5432"
    DB_NAME       = module.database.database_name
    DB_SCHEMA     = local.db_schema
    DB_USER       = "app"
    DB_SSL_MODE   = "require"
    ASSETS_BUCKET = module.assets_bucket.name
  }

  secrets = {
    DB_PASSWORD = { secret = module.db_app_password.secret_id }
  }
}

module "asset_cleaner_schedule" {
  source = "../modules/cloud-scheduler-job"

  project_id      = var.project_id
  name            = "asset-cleaner"
  region          = var.region
  job_name        = module.asset_cleaner.name
  service_account = local.sa_email["scheduler"]

  description = "Deletes bucket objects with no assets row, and pending rows past their grace period."
  schedule    = "0 3 * * *"
  time_zone   = local.scheduler_timezone
  paused      = true
}

module "grant_staff" {
  source = "../modules/cloud-run-job"

  project_id = var.project_id
  name       = "grant-staff"
  region     = var.region
  # The API's own identity: it already holds firebaseauth.admin and reads the
  # same database password, and this job does nothing the API cannot do.
  service_account = local.sa_email["api"]

  deletion_protection = var.deletion_protection

  parallelism = 1
  task_count  = 1
  timeout     = "300s"

  resource_limits = { cpu = "1", memory = "512Mi" }

  # Runs from the API image, which carries this binary alongside the server.
  # Arguments are passed per execution, so the job holds none.
  command = ["/grant-staff"]

  vpc_access = {
    network    = module.network.id
    subnetwork = module.network.subnets[local.subnet_run].id
    # The database is private, the identity provider is not.
    egress = "all-traffic"
  }

  env = {
    DB_HOST     = module.database.private_ip_address
    DB_PORT     = "5432"
    DB_NAME     = module.database.database_name
    DB_SCHEMA   = local.db_schema
    DB_USER     = "app"
    DB_SSL_MODE = "require"

    DB_MIN_CONNS = "1"
    DB_MAX_CONNS = "2"

    ENV                      = "development"
    LOG_FORMAT               = "json"
    LOG_LEVEL                = "info"
    LOG_ENABLE_CLOUD_LOGGING = "true"
  }

  secrets = {
    DB_PASSWORD = { secret = module.db_app_password.secret_id }
  }
}
