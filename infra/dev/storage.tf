module "assets_bucket" {
  source = "../modules/storage-bucket"

  project_id    = var.project_id
  name          = "${local.bucket_prefix}-assets"
  random_suffix = true
  location      = var.region

  versioning    = false
  force_destroy = !var.deletion_protection

  object_admins = [
    local.sa_member["api"],
    local.sa_member["asset-cleaner"]
  ]
}

module "registry" {
  source = "../modules/docker-repository"

  project_id    = var.project_id
  region        = var.region
  repository_id = "containers"

  tagged_keep_count       = 5
  untagged_retention_days = 7

  reader_members = [local.sa_member["gha-deployer"]]
  writer_members = [local.sa_member["gha-deployer"]]
}
