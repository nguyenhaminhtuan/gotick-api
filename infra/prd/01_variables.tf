variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

variable "app_name" {
  type    = string
  default = "gotick"
}

variable "domain" {
  type = string
}

variable "enable_db_provision" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = true
}


variable "developers" {
  type = list(string)

  validation {
    condition     = length(var.developers) > 0
    error_message = "At least one member, or nobody can operate the database."
  }

  validation {
    condition     = alltrue([for m in var.developers : can(regex("^(user|group|serviceAccount|domain):", m))])
    error_message = "Each member needs its type prefix, for example user:you@gmail.com."
  }
}

variable "identity_google_oauth_client_id" {
  description = "Google sign-in client. Null keeps the provider off."
  type        = string
  default     = null
}

variable "identity_google_oauth_client_secret" {
  type      = string
  sensitive = true
  default   = null
}
