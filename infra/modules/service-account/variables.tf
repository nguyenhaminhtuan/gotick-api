variable "project_id" {
  type = string
}

variable "account_id" {
  description = "IAM requires 6-30 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.account_id))
    error_message = "Must be 6-30 characters, lowercase letters, digits and hyphens, starting with a letter and ending with a letter or digit."
  }
}

variable "display_name" {
  type    = string
  default = null
}

variable "description" {
  type    = string
  default = null
}

variable "project_roles" {
  description = "Project-level roles granted to this account."
  type        = list(string)
  default     = []
}

variable "user_members" {
  description = "Members granted roles/iam.serviceAccountUser, which is what attaching this account to a resource requires."
  type        = list(string)
  default     = []
}

variable "token_creators" {
  description = "Members granted roles/iam.serviceAccountTokenCreator, which is what impersonating this account requires. Attaching and impersonating are different acts, so they are different lists."
  type        = list(string)
  default     = []
}
