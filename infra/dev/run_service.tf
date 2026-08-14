module "api" {
  source = "../modules/cloud-run-service"

  project_id      = var.project_id
  name            = "api"
  region          = var.region
  service_account = local.sa_email["api"]

  ingress       = "internal-and-lb"
  min_instances = 0
  startup_probe = { path = "/health" }

  max_instances   = 3
  concurrency     = 40
  resource_limits = { cpu = "1", memory = "1Gi" }
  request_timeout = "60s"

  allow_unauthenticated = true
  deletion_protection   = var.deletion_protection

  vpc_access = {
    network    = module.network.id
    subnetwork = module.network.subnets[local.subnet_run].id
    egress     = "all-traffic"
  }

  env = {
    DB_HOST     = module.database.private_ip_address
    DB_PORT     = "5432"
    DB_NAME     = module.database.database_name
    DB_SCHEMA   = local.db_schema
    DB_USER     = "app"
    DB_SSL_MODE = "require"

    DB_MIN_CONNS = "0"
    DB_MAX_CONNS = "5"

    ENV                      = "development"
    LOG_FORMAT               = "json"
    LOG_LEVEL                = "info"
    LOG_ENABLE_CLOUD_LOGGING = "true"
  }

  secrets = {
    DB_PASSWORD = { secret = module.db_app_password.secret_id }
  }
}

module "docs" {
  source = "../modules/cloud-run-service"

  project_id      = var.project_id
  name            = "docs"
  region          = var.region
  service_account = local.sa_email["docs"]

  ingress       = "internal-and-lb"
  min_instances = 0
  startup_probe = { path = "/health" }

  max_instances         = 1
  resource_limits       = { cpu = "1", memory = "256Mi" }
  execution_environment = "gen1"

  allow_unauthenticated = true

  deletion_protection = var.deletion_protection
}
