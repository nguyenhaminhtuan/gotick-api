locals {
  job_run_uri = format(
    "https://%s-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/%s/jobs/%s:run",
    var.region, var.project_id, var.job_name,
  )
}

resource "google_cloud_scheduler_job" "this" {
  project     = var.project_id
  region      = var.region
  name        = var.name
  description = var.description
  schedule    = var.schedule
  time_zone   = var.time_zone
  paused      = var.paused

  attempt_deadline = var.attempt_deadline

  retry_config {
    retry_count          = var.retry_count
    min_backoff_duration = var.min_backoff
    max_backoff_duration = var.max_backoff
  }

  http_target {
    http_method = "POST"
    uri         = local.job_run_uri

    oauth_token {
      service_account_email = var.service_account
    }
  }
}

resource "google_cloud_run_v2_job_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  name     = var.job_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account}"
}
