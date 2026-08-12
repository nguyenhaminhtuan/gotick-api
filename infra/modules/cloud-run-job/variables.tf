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
  default = "us-docker.pkg.dev/cloudrun/container/job"
}

variable "service_account" {
  type    = string
  default = null
}

variable "command" {
  type    = list(string)
  default = null
}

variable "args" {
  type    = list(string)
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

variable "max_retries" {
  description = "Retries per task. 0 fails the execution on the first failed task."
  type        = number
  default     = 0
}

variable "timeout" {
  description = "Per task, as a duration string like \"600s\"."
  type        = string
  default     = null
}

variable "parallelism" {
  type    = number
  default = null
}

variable "task_count" {
  type    = number
  default = null
}

variable "deletion_protection" {
  type    = bool
  default = false
}
