locals {
  execution_environment = {
    gen1 = "EXECUTION_ENVIRONMENT_GEN1"
    gen2 = "EXECUTION_ENVIRONMENT_GEN2"
  }

  egress = {
    all-traffic         = "ALL_TRAFFIC"
    private-ranges-only = "PRIVATE_RANGES_ONLY"
  }
}

resource "google_cloud_run_v2_job" "this" {
  project  = var.project_id
  name     = var.name
  location = var.region

  deletion_protection = var.deletion_protection

  template {
    parallelism = var.parallelism
    task_count  = var.task_count

    template {
      service_account       = var.service_account
      execution_environment = local.execution_environment[var.execution_environment]
      max_retries           = var.max_retries
      timeout               = var.timeout

      dynamic "vpc_access" {
        for_each = var.vpc_access == null ? [] : [var.vpc_access]

        content {
          egress = local.egress[vpc_access.value.egress]

          network_interfaces {
            network    = vpc_access.value.network
            subnetwork = vpc_access.value.subnetwork
          }
        }
      }

      containers {
        name    = var.name
        image   = var.image
        args    = var.args
        command = var.command

        dynamic "env" {
          for_each = var.env

          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = var.secrets

          content {
            name = env.key

            value_source {
              secret_key_ref {
                secret  = env.value.secret
                version = env.value.version
              }
            }
          }
        }

        dynamic "resources" {
          for_each = var.resource_limits == null ? [] : [var.resource_limits]

          content {
            limits = resources.value
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      template[0].labels,
      template[0].annotations,
      labels,
      annotations,
      client,
      client_version,
    ]
  }
}
