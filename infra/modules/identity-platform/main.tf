terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_identity_platform_config" "this" {
  project = var.project_id

  sign_in {
    allow_duplicate_emails = var.allow_duplicate_emails

    email {
      enabled           = var.email_sign_in.enabled
      password_required = var.email_sign_in.password_required
    }

    phone_number {
      enabled            = var.phone_sign_in.enabled
      test_phone_numbers = var.phone_sign_in.test_numbers
    }
  }

  authorized_domains = var.authorized_domains

  dynamic "quota" {
    for_each = var.sign_up_quota == null ? [] : [var.sign_up_quota]

    content {
      sign_up_quota_config {
        quota          = quota.value.quota
        quota_duration = quota.value.duration
        start_time     = ""
      }
    }
  }
}

resource "google_identity_platform_default_supported_idp_config" "google" {
  count = var.google_oauth_client == null ? 0 : 1

  project       = var.project_id
  idp_id        = "google.com"
  enabled       = true
  client_id     = var.google_oauth_client.client_id
  client_secret = var.google_oauth_client.client_secret

  depends_on = [google_identity_platform_config.this]
}
