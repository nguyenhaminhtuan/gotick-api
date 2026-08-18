variable "project_id" {
  description = "The whole project id, or the stable part of it when a suffix is added below."
  type        = string
}

variable "suffix" {
  description = "Appended as -<suffix>. For when uniqueness comes from a value the caller already holds."
  type        = string
  default     = null
}

variable "random_suffix" {
  description = <<-EOT
    Appends a generated suffix instead. Project ids share one namespace across
    all of Google Cloud and are never reusable after a delete, so a readable id
    is rarely free to take.

    Either way, read the final id back from the project_id output.
  EOT

  type    = bool
  default = false

  validation {
    condition     = !(var.random_suffix && var.suffix != null)
    error_message = "Set suffix or random_suffix, not both."
  }
}

variable "name" {
  description = "Display name. Must match the existing project when importing."
  type        = string
}

variable "billing_account" {
  description = "Billing account id. Not optional: the field is not computed, so leaving it unset on an imported project plans to detach billing."
  type        = string
}

variable "org_id" {
  description = "Organization id. Mutually exclusive with folder_id. A wrong value plans to migrate the project."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Folder id. Mutually exclusive with org_id."
  type        = string
  default     = null
}


variable "auto_create_network" {
  description = "Leave null when importing: setting false on an existing project deletes its default network."
  type        = bool
  default     = null
}

variable "deletion_policy" {
  description = "PREVENT blocks destroy at the provider level."
  type        = string
  default     = "PREVENT"

  validation {
    condition     = contains(["PREVENT", "ABANDON", "DELETE"], var.deletion_policy)
    error_message = "Must be PREVENT, ABANDON or DELETE."
  }
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "services" {
  description = "APIs enabled on the project."
  type        = list(string)
  default     = []
}

variable "enable_firebase" {
  description = "Turns the project into a Firebase project: enables firebase.googleapis.com alongside services, and labels the project firebase = \"enabled\" the way the console does."
  type        = bool
  default     = false
}

variable "disable_services_on_destroy" {
  description = "Turns each API off as it is destroyed, which fails whenever another enabled API still depends on it. False leaves them on, which is what a project being deleted whole wants anyway."
  type        = bool
  default     = false
}
