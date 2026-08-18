locals {
  identity_config_file = "${path.root}/identity-config.json"
  identity_update_mask = join(",", keys(jsondecode(file(local.identity_config_file))))
}

module "identity_platform" {
  source = "../modules/identity-platform"

  project_id = var.project_id

  authorized_domains = [
    var.domain,
  ]

  allow_duplicate_emails = false

  email_sign_in = {
    enabled           = true
    password_required = true
  }

  phone_sign_in = {
    enabled      = true
    test_numbers = {}
  }

  google_oauth_client = var.identity_google_oauth_client_id == null ? null : {
    client_id     = var.identity_google_oauth_client_id
    client_secret = var.identity_google_oauth_client_secret
  }

  sign_up_quota = {
    quota    = 500
    duration = "7200s"
  }
}

module "identity_config" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 4.0"

  create_cmd_entrypoint = "curl"
  create_cmd_body       = "--fail-with-body -sS -X PATCH -H \"Authorization: Bearer $(gcloud auth print-access-token $${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT:+--impersonate-service-account=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT})\" -H 'Content-Type: application/json' -d @${local.identity_config_file} 'https://identitytoolkit.googleapis.com/admin/v2/projects/${var.project_id}/config?updateMask=${local.identity_update_mask}'"

  create_cmd_triggers = {
    project = var.project_id
    config  = filesha256(local.identity_config_file)
  }

  skip_download = true

  module_depends_on = [module.identity_platform.name]
}
