variable "project_id" {
  type = string
}

variable "github_owner" {
  description = "GitHub org or user."
  type        = string
}

variable "github_repo" {
  description = "Repository name."
  type        = string
}

variable "service_account_ids" {
  description = "Fully qualified ids of accounts any workflow in this repository may impersonate."
  type        = list(string)
  default     = []
}

variable "environment_service_account_ids" {
  description = <<-EOT
    Accounts reachable only from a job running in the named GitHub environment,
    keyed by environment name. Narrower than service_account_ids, which any
    branch can reach.
  EOT
  type        = map(list(string))
  default     = {}
}

variable "pool_id" {
  type    = string
  default = "github"
}

variable "provider_id" {
  type    = string
  default = "github-oidc"
}

variable "display_name" {
  type    = string
  default = "GitHub"
}
