variable "app_name" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "developers" {
  type    = list(string)
  default = []

  validation {
    condition     = alltrue([for m in var.developers : can(regex("^(user|group|serviceAccount|domain):", m))])
    error_message = "Each member needs its type prefix, for example user:you@gmail.com."
  }
}

variable "deletion_protection" {
  type    = bool
  default = true
}
