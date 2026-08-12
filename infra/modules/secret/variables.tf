variable "project_id" {
  type = string
}

variable "secret_id" {
  type = string
}

variable "secret_data" {
  type      = string
  default   = null
  ephemeral = true
}

variable "secret_version" {
  type    = number
  default = null
}

variable "version_deletion_policy" {
  type    = string
  default = "DISABLE"

  validation {
    condition     = contains(["DELETE", "DISABLE", "ABANDON"], var.version_deletion_policy)
    error_message = "Must be DELETE, DISABLE or ABANDON."
  }
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "topics" {
  description = <<-EOT
    Pub/Sub topics, as projects/*/topics/*, that receive this secret's event
    notifications. The Secret Manager service agent needs roles/pubsub.publisher
    on each one before the secret is written, because the API verifies it can
    publish and fails the write when it cannot.
  EOT

  type    = list(string)
  default = []
}

variable "rotation" {
  description = <<-EOT
    Publishes a SECRET_ROTATE message to topics at next_rotation_time, then
    advances that time by rotation_period. It does not change the secret: the
    subscriber is what has to write a new version, so a rotation policy with no
    subscriber is a reminder nobody receives.

    next_rotation_time is RFC3339 UTC and defaults to 24h after the apply that
    creates the secret. rotation_period is seconds, between 3600s and
    3153600000s.
  EOT

  type = object({
    rotation_period    = string
    next_rotation_time = optional(string)
  })

  default = null

  validation {
    condition     = var.rotation == null || length(var.topics) > 0
    error_message = "rotation needs at least one topic: Secret Manager refuses a rotation policy with nowhere to publish."
  }

  validation {
    condition     = var.rotation == null || try(tonumber(trimsuffix(var.rotation.rotation_period, "s")), 0) >= 3600
    error_message = "rotation_period must be seconds with an s suffix, at least 3600s."
  }
}

variable "accessors" {
  description = "Members granted roles/secretmanager.secretAccessor on this one secret, rather than on the project."
  type        = list(string)
  default     = []
}

variable "replica_locations" {
  description = "Null replicates automatically. A list pins the secret to those regions."
  type        = list(string)
  default     = null
}
