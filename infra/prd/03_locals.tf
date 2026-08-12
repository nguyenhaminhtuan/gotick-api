locals {
  env_code    = "prd"
  region_code = replace(var.region, "-", "")

  vpc             = "vpc-${local.env_code}-main"
  subnet_run      = "sn-${local.env_code}-main-${local.region_code}-run"
  subnet_internal = "sn-${local.env_code}-main-${local.region_code}-internal"
  sql_instance    = "sql-${local.env_code}-${var.app_name}-${random_id.sql.hex}"
  load_balancer   = "lb-${local.env_code}-main"
  bucket_prefix   = "bkt-${var.app_name}-${local.env_code}"

  psa_range_address       = "10.20.0.0"
  psa_range_prefix_length = 16

  scheduler_timezone = "Asia/Ho_Chi_Minh"

  db_provision = var.enable_db_provision ? 1 : 0
  db_name      = "gotick"
  db_schema    = "app"
  db_password_version = {
    app      = 1
    migrate  = 1
    postgres = 1
  }

  sa_email = {
    for name in ["gha-infra", "gha-deployer", "api", "migrate", "asset-cleaner", "scheduler", "bastion", "db-admin"] :
    name => "sa-${name}@${var.project_id}.iam.gserviceaccount.com"
  }
  sa_member = { for name, email in local.sa_email : name => "serviceAccount:${email}" }
}

resource "random_id" "sql" {
  byte_length = 2
}
