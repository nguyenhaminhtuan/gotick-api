variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "job_name" {
  description = "Cloud Run job this triggers."
  type        = string
}

variable "service_account" {
  description = "Email Scheduler authenticates as. It is granted run.invoker on the job here."
  type        = string
}

variable "schedule" {
  description = "Unix cron, read in time_zone."
  type        = string
}

variable "time_zone" {
  description = "IANA name. Naming a zone rather than UTC keeps the schedule where it was meant to be across daylight saving."
  type        = string
  default     = "Etc/UTC"
}

variable "description" {
  type    = string
  default = null
}

variable "paused" {
  description = "Creates the schedule without letting it fire, for a job whose image or data it depends on does not exist yet."
  type        = bool
  default     = false
}

variable "attempt_deadline" {
  description = "How long Scheduler waits for the run call to be accepted. It does not bound the job itself."
  type        = string
  default     = "320s"
}

variable "retry_count" {
  description = "Retries of the trigger call, not of the job."
  type        = number
  default     = 3
}

variable "min_backoff" {
  type    = string
  default = "5s"
}

variable "max_backoff" {
  type    = string
  default = "3600s"
}
