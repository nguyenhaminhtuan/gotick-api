terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  availability_type = var.high_availability ? "REGIONAL" : "ZONAL"

  tiers = {
    enterprise-micro = { machine_type = "db-f1-micro", edition = "ENTERPRISE" }
    enterprise-small = { machine_type = "db-g1-small", edition = "ENTERPRISE" }

    enterprise-1  = { machine_type = "db-custom-1-3840", edition = "ENTERPRISE" }
    enterprise-2  = { machine_type = "db-custom-2-7680", edition = "ENTERPRISE" }
    enterprise-4  = { machine_type = "db-custom-4-15360", edition = "ENTERPRISE" }
    enterprise-8  = { machine_type = "db-custom-8-30720", edition = "ENTERPRISE" }
    enterprise-16 = { machine_type = "db-custom-16-61440", edition = "ENTERPRISE" }

    enterprise-plus-2  = { machine_type = "db-perf-optimized-N-2", edition = "ENTERPRISE_PLUS" }
    enterprise-plus-4  = { machine_type = "db-perf-optimized-N-4", edition = "ENTERPRISE_PLUS" }
    enterprise-plus-8  = { machine_type = "db-perf-optimized-N-8", edition = "ENTERPRISE_PLUS" }
    enterprise-plus-16 = { machine_type = "db-perf-optimized-N-16", edition = "ENTERPRISE_PLUS" }
    enterprise-plus-32 = { machine_type = "db-perf-optimized-N-32", edition = "ENTERPRISE_PLUS" }
  }

  tier = local.tiers[var.tier]

  ssl_mode = {
    allow-unencrypted  = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    encrypted-only     = "ENCRYPTED_ONLY"
    client-certificate = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
  }

  maintenance_day = {
    monday    = 1
    tuesday   = 2
    wednesday = 3
    thursday  = 4
    friday    = 5
    saturday  = 6
    sunday    = 7
  }

  update_track = ["canary", "stable", "week5"]
}

resource "google_compute_global_address" "peering" {
  project       = var.project_id
  name          = "${var.name}-psa"
  network       = var.network
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.peering_range_address
  prefix_length = var.peering_range_prefix_length
}

resource "google_service_networking_connection" "this" {
  network                 = var.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.peering.name]
}


resource "google_sql_database_instance" "this" {
  project          = var.project_id
  name             = var.name
  region           = var.region
  database_version = var.database_version

  deletion_protection = var.deletion_protection

  settings {
    tier              = local.tier.machine_type
    edition           = local.tier.edition
    availability_type = local.availability_type
    activation_policy = var.activation_policy
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    deletion_protection_enabled = var.deletion_protection

    ip_configuration {
      # No public IP: every consumer reaches this over the peering above.
      ipv4_enabled    = var.public_ip
      private_network = var.network
      ssl_mode        = local.ssl_mode[var.ssl_mode]
    }

    dynamic "password_validation_policy" {
      for_each = var.password_policy == null ? [] : [var.password_policy]

      content {
        enable_password_policy      = true
        min_length                  = password_validation_policy.value.min_length
        reuse_interval              = password_validation_policy.value.reuse_interval
        disallow_username_substring = password_validation_policy.value.disallow_username_substring
        complexity                  = password_validation_policy.value.complexity
        password_change_interval    = password_validation_policy.value.password_change_interval
      }
    }

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.point_in_time_recovery

      backup_retention_settings {
        retained_backups = var.retained_backups
      }
    }

    dynamic "maintenance_window" {
      for_each = var.maintenance_window == null ? [] : [var.maintenance_window]

      content {
        day          = local.maintenance_day[maintenance_window.value.day]
        hour         = maintenance_window.value.hour
        update_track = maintenance_window.value.update_track
      }
    }

    dynamic "connection_pool_config" {
      for_each = var.connection_pool == null ? [] : [var.connection_pool]

      content {
        connection_pooling_enabled = connection_pool_config.value.enabled

        dynamic "flags" {
          for_each = connection_pool_config.value.flags

          content {
            name  = flags.key
            value = flags.value
          }
        }
      }
    }

    dynamic "database_flags" {
      for_each = var.database_flags

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  depends_on = [google_service_networking_connection.this]
}

resource "google_sql_database_instance" "read_pool" {
  count = var.read_pool == null ? 0 : 1

  project              = var.project_id
  name                 = "${var.name}-pool"
  region               = var.region
  database_version     = var.database_version
  master_instance_name = google_sql_database_instance.this.name
  instance_type        = "READ_POOL_INSTANCE"
  node_count           = var.read_pool.node_count

  deletion_protection = var.deletion_protection

  settings {
    tier            = var.read_pool.tier == null ? local.tier.machine_type : local.tiers[var.read_pool.tier].machine_type
    edition         = local.tier.edition
    disk_autoresize = var.disk_autoresize

    ip_configuration {
      ipv4_enabled    = var.public_ip
      private_network = var.network
      ssl_mode        = local.ssl_mode[var.ssl_mode]
    }

    dynamic "maintenance_window" {
      for_each = var.maintenance_window == null ? [] : [var.maintenance_window]

      content {
        day          = local.maintenance_day[maintenance_window.value.day]
        hour         = maintenance_window.value.hour
        update_track = maintenance_window.value.update_track
      }
    }
  }
}

resource "google_sql_database" "this" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.database_name
}

resource "google_sql_user" "this" {
  for_each = var.users

  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = each.key
  type     = each.value.type

  # An IAM user has no password: Cloud SQL authenticates it with an access token.
  password_wo         = each.value.type == null ? var.user_passwords[each.key] : null
  password_wo_version = each.value.password_version

  # Write-only: the API never reads it back, so a role revoked by hand outside
  # Terraform looks like no drift at all.
  database_roles = each.value.database_roles
}
