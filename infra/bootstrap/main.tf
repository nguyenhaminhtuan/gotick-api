terraform {
  required_version = ">= 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # backend "local" {
  # }

  backend "gcs" {
  }
}

provider "google" {
  region = var.region
}

provider "google-beta" {
  region = var.region
}

locals {
  project_prefix = "prj-${var.app_name}"
  bucket_prefix  = "bkt-${var.app_name}"

  base_enabled_apis = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com"
  ]

  env_enabled_apis = concat(local.base_enabled_apis, [
    "artifactregistry.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "identitytoolkit.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "sts.googleapis.com",
  ])

  common_infra_project_roles = [
    "roles/serviceusage.serviceUsageAdmin",

    "roles/compute.instanceAdmin.v1",
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    "roles/compute.loadBalancerAdmin",
    "roles/servicenetworking.networksAdmin",
    "roles/certificatemanager.owner",
    "roles/iap.admin",

    "roles/storage.admin",
    "roles/artifactregistry.admin",
    "roles/run.admin",
    "roles/cloudscheduler.admin",
    "roles/cloudsql.admin",
    "roles/secretmanager.admin",
    "roles/identityplatform.admin",
  ]

  env = {
    dev = {
      enable_firebase     = true
      enabled_apis        = concat(local.env_enabled_apis, [])
      infra_project_roles = concat(local.common_infra_project_roles, [])
    }
    prd = {
      enable_firebase     = true
      enabled_apis        = concat(local.env_enabled_apis, [])
      infra_project_roles = concat(local.common_infra_project_roles, [])
    }
  }

  deletion_policy = var.deletion_protection ? "PREVENT" : "DELETE"
}

module "seed_project" {
  source = "../modules/project"

  project_id          = "${local.project_prefix}-seed"
  random_suffix       = true
  name                = "${var.app_name} seed"
  billing_account     = var.billing_account
  enable_firebase     = false
  auto_create_network = false
  services            = local.base_enabled_apis
  deletion_policy     = local.deletion_policy
}

module "seed_bucket_state" {
  source = "../modules/storage-bucket"

  project_id    = module.seed_project.project_id
  name          = "${local.bucket_prefix}-seed"
  random_suffix = true
  location      = var.region
  keep_versions = 30
  force_destroy = false
}

module "env_project" {
  source = "../modules/project"

  for_each            = local.env
  project_id          = "${local.project_prefix}-${each.key}"
  random_suffix       = true
  name                = "${var.app_name} ${each.key}"
  billing_account     = var.billing_account
  enable_firebase     = each.value.enable_firebase
  auto_create_network = false
  services            = each.value.enabled_apis
  deletion_policy     = local.deletion_policy
}

module "env_state_bucket" {
  source = "../modules/storage-bucket"

  for_each      = local.env
  project_id    = module.env_project[each.key].project_id
  name          = "${local.bucket_prefix}-${each.key}"
  random_suffix = true
  location      = var.region
  keep_versions = 30
  force_destroy = !var.deletion_protection
}
