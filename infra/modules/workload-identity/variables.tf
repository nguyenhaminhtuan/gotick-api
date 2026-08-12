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
  description = "Fully qualified ids of accounts this repository may impersonate."
  type        = list(string)
  default     = []
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
