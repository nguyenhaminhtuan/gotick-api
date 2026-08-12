variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "image" {
  type    = string
  default = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "service_account" {
  type    = string
  default = null
}

variable "ingress" {
  type    = string
  default = "internal-and-lb"

  validation {
    condition     = contains(keys(local.ingress), var.ingress)
    error_message = format("Must be one of: %s.", join(", ", keys(local.ingress)))
  }
}

variable "port" {
  type    = number
  default = 8080
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = null
}

variable "concurrency" {
  type    = number
  default = null
}

variable "execution_environment" {
  type    = string
  default = "gen2"

  validation {
    condition     = contains(keys(local.execution_environment), var.execution_environment)
    error_message = format("Must be one of: %s.", join(", ", keys(local.execution_environment)))
  }
}

variable "vpc_access" {
  type = object({
    network    = string
    subnetwork = string
    egress     = optional(string, "private-ranges-only")
  })

  default = null
}

variable "env" {
  type    = map(string)
  default = {}
}

variable "secrets" {
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))

  default = {}
}

variable "resource_limits" {
  type    = map(string)
  default = null
}

variable "startup_probe" {
  type = object({
    path                  = string
    initial_delay_seconds = optional(number, 0)
    period_seconds        = optional(number, 3)
    timeout_seconds       = optional(number, 3)
    failure_threshold     = optional(number, 10)
  })

  default = null
}

variable "traffic" {
  type = list(object({
    type     = optional(string, "latest")
    revision = optional(string)
    percent  = optional(number, 100)
    tag      = optional(string)
  }))

  default = []

  validation {
    condition     = alltrue([for t in var.traffic : contains(keys(local.traffic_type), t.type)])
    error_message = format("traffic type must be one of: %s.", join(", ", keys(local.traffic_type)))
  }
}

variable "allow_unauthenticated" {
  description = "Grants roles/run.invoker to allUsers. Ingress still governs who can open a connection at all."
  type        = bool
  default     = false
}

variable "invokers" {
  description = "Additional members granted roles/run.invoker, for callers that authenticate."
  type        = list(string)
  default     = []
}

variable "iap_enabled" {
  description = "Puts Identity-Aware Proxy in front of the service, using a Google-managed OAuth client. It also covers a load balancer placed in front, and cannot be combined with IAP on the load balancer's backend service."
  type        = bool
  default     = false
}

variable "iap_members" {
  description = "Members granted roles/iap.httpsResourceAccessor on this service, in user: or group: form."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for m in var.iap_members : can(regex("^(user|group|serviceAccount|domain):", m))])
    error_message = "Each member needs its type prefix, for example user:you@gmail.com."
  }
}

variable "deletion_protection" {
  description = "The provider defaults this to true, which makes destroy fail."
  type        = bool
  default     = false
}

variable "cpu_idle" {
  description = "True bills CPU only while a request is in flight. False keeps it allocated for the instance's whole life."
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Extra CPU while a new instance starts."
  type        = bool
  default     = true
}

variable "request_timeout" {
  description = "Duration string such as \"300s\". Null keeps the Cloud Run default of 5 minutes."
  type        = string
  default     = null
}

variable "default_uri_disabled" {
  description = "Stops the run.app URL from resolving at all."
  type        = bool
  default     = false
}
