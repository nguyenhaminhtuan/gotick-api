resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = var.display_name
  description  = var.description
}

resource "google_project_iam_member" "this" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = google_service_account.this.member
}

# count rather than for_each: a member here is often another account's email,
# which is built from a project id that does not exist until apply. for_each
# would be asked to use that unknown string as an instance key.
resource "google_service_account_iam_member" "user" {
  count = length(var.user_members)

  service_account_id = google_service_account.this.name
  role               = "roles/iam.serviceAccountUser"
  member             = var.user_members[count.index]
}

resource "google_service_account_iam_member" "token_creator" {
  count = length(var.token_creators)

  service_account_id = google_service_account.this.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.token_creators[count.index]
}
