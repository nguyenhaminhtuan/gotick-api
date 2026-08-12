locals {
  ingress = {
    all             = "INGRESS_TRAFFIC_ALL"
    internal        = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    internal-and-lb = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }

  execution_environment = {
    gen1 = "EXECUTION_ENVIRONMENT_GEN1"
    gen2 = "EXECUTION_ENVIRONMENT_GEN2"
  }

  egress = {
    all-traffic         = "ALL_TRAFFIC"
    private-ranges-only = "PRIVATE_RANGES_ONLY"
  }

  traffic_type = {
    latest   = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    revision = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
  }

  invokers = merge(
    { for i, m in var.invokers : "invoker-${i}" => m },
    var.allow_unauthenticated ? { all-users = "allUsers" } : {},
  )
}

resource "google_cloud_run_v2_service" "this" {
  project  = var.project_id
  name     = var.name
  location = var.region

  ingress              = local.ingress[var.ingress]
  iap_enabled          = var.iap_enabled
  default_uri_disabled = var.default_uri_disabled
  deletion_protection  = var.deletion_protection

  template {
    service_account                  = var.service_account
    execution_environment            = local.execution_environment[var.execution_environment]
    max_instance_request_concurrency = var.concurrency
    timeout                          = var.request_timeout

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

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
      name  = var.name
      image = var.image

      ports {
        container_port = var.port
      }

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

      resources {
        limits            = var.resource_limits
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      dynamic "startup_probe" {
        for_each = var.startup_probe == null ? [] : [var.startup_probe]

        content {
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          period_seconds        = startup_probe.value.period_seconds
          timeout_seconds       = startup_probe.value.timeout_seconds
          failure_threshold     = startup_probe.value.failure_threshold

          http_get {
            path = startup_probe.value.path
            port = var.port
          }
        }
      }
    }
  }

  dynamic "traffic" {
    for_each = var.traffic

    content {
      type     = local.traffic_type[traffic.value.type]
      revision = traffic.value.revision
      percent  = traffic.value.percent
      tag      = traffic.value.tag
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].labels,
      template[0].annotations,
      template[0].revision,
      traffic,
      labels,
      annotations,
      client,
      client_version,
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "invoker" {
  for_each = local.invokers

  project  = google_cloud_run_v2_service.this.project
  location = google_cloud_run_v2_service.this.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = each.value
}

resource "google_iap_web_cloud_run_service_iam_member" "accessor" {
  for_each = { for i, m in var.iap_members : "member-${i}" => m }

  project                = google_cloud_run_v2_service.this.project
  location               = google_cloud_run_v2_service.this.location
  cloud_run_service_name = google_cloud_run_v2_service.this.name
  role                   = "roles/iap.httpsResourceAccessor"
  member                 = each.value
}
