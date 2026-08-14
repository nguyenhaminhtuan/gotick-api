module "api" {
  source = "../modules/cloud-run-service"

  project_id      = var.project_id
  name            = "api"
  region          = var.region
  service_account = local.sa_email["api"]

  ingress       = "internal-and-lb"
  min_instances = 1
  startup_probe = { path = "/health" }

  max_instances   = 20
  concurrency     = 40
  resource_limits = { cpu = "1", memory = "512Mi" }
  request_timeout = "60s"

  allow_unauthenticated = true
  deletion_protection   = var.deletion_protection

  vpc_access = {
    network    = module.network.id
    subnetwork = module.network.subnets[local.subnet_run].id
    egress     = "all-traffic"
  }

  env = {
    DB_HOST      = module.database.private_ip_address
    DB_PORT      = "6432"
    DB_READ_HOST = module.database.read_pool_private_ip_address
    DB_READ_PORT = "5432"
    DB_NAME      = module.database.database_name
    DB_SCHEMA    = local.db_schema
    DB_USER      = "app"
    DB_SSL_MODE  = "require"

    ENV                      = "production"
    LOG_FORMAT               = "json"
    LOG_LEVEL                = "info"
    LOG_ENABLE_CLOUD_LOGGING = "true"
  }

  secrets = {
    DB_PASSWORD = { secret = module.db_app_password.secret_id }
  }
}
