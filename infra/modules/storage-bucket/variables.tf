variable "project_id" {
  type = string
}

variable "name" {
  description = "The whole bucket name, or the stable part of it when a suffix is added below."
  type        = string
}

variable "suffix" {
  description = "Appended as -<suffix>. For when uniqueness comes from a value the caller already holds, such as a project id or an existing random_id."
  type        = string
  default     = null
}

variable "random_suffix" {
  description = <<-EOT
    Appends a generated suffix instead. Bucket names share one namespace across
    all of Google Cloud, so a readable name is rarely free to take, and this
    saves every caller inventing its own source of randomness.

    Either way, read the final name back from the name output.
  EOT

  type    = bool
  default = false

  validation {
    condition     = !(var.random_suffix && var.suffix != null)
    error_message = "Set suffix or random_suffix, not both."
  }
}

variable "location" {
  type = string
}

variable "versioning" {
  description = "Keep non-current generations of an object."
  type        = bool
  default     = true
}

variable "keep_versions" {
  description = "Non-current generations to retain. null keeps every generation forever."
  type        = number
  default     = null
}

variable "force_destroy" {
  description = "Deletes the objects along with the bucket. Without it a destroy fails on anything that is not already empty."
  type        = bool
  default     = false
}

variable "object_admins" {
  description = "Members granted roles/storage.objectAdmin on this bucket alone, rather than on the project."
  type        = list(string)
  default     = []
}

variable "object_viewers" {
  description = "Members granted roles/storage.objectViewer on this bucket alone."
  type        = list(string)
  default     = []
}

variable "cors" {
  description = "Browser origins allowed to reach objects directly. Empty means none, which is right whenever objects are only ever served through signed URLs."

  type = list(object({
    origins          = list(string)
    methods          = optional(list(string), ["GET", "HEAD"])
    response_headers = optional(list(string), ["Content-Type"])
    max_age_seconds  = optional(number, 3600)
  }))

  default = []
}

variable "lifecycle_age_days" {
  description = "Deletes an object this many days after creation. Null keeps objects forever."
  type        = number
  default     = null
}
