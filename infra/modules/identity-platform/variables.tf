variable "project_id" {
  type = string
}

variable "authorized_domains" {
  description = "Hosts allowed to start a sign-in. Everything else is refused as an origin."
  type        = list(string)
}

variable "allow_duplicate_emails" {
  type = bool
}

variable "email_sign_in" {
  type = object({
    enabled           = bool
    password_required = bool
  })
}

variable "phone_sign_in" {
  type = object({
    enabled      = bool
    test_numbers = map(string)
  })
}

variable "google_oauth_client" {
  type = object({
    client_id     = string
    client_secret = string
  })

  default   = null
  sensitive = true
}

variable "sign_up_quota" {
  description = "Caps new identities per window, the blunt lever against automated sign-ups. Null leaves the project default."

  type = object({
    quota    = number
    duration = string
  })

  default = null
}
