variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "zone" {
  description = "Pinned. Spot capacity differs by zone, and gcloud compute ssh needs this value."
  type        = string
}

variable "region" {
  description = "Must match the instance's region, or the schedule policy cannot attach."
  type        = string
}

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "service_account_email" {
  description = "The bastion calls no Google API, so this account needs no role. It exists for the firewall to target and for OS Login to attach an identity to."
  type        = string
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "image" {
  type    = string
  default = "debian-cloud/debian-12"
}

variable "disk_size" {
  description = "GB. A disk bills while the machine is off, so keep it small."
  type        = number
  default     = 10
}

variable "spot" {
  description = <<-EOT
    Spot costs less but can be reclaimed at any moment, including in the middle
    of a terraform apply.

    Uses provisioning_model = SPOT rather than preemptible: preemptible is the
    older model and carries a hard 24 hour cap.
  EOT

  type    = bool
  default = false
}

variable "schedule" {
  description = <<-EOT
    Start/stop schedule. Null leaves the machine running until somebody stops it.

    A schedule does not know whether anyone is working: it stops the instance
    whether or not an SSH session or a terraform apply is in flight. It is a
    safety net rather than the primary mechanism, so put it at an hour nobody
    runs anything.
  EOT

  type = object({
    time_zone = string
    start     = optional(string)
    stop      = string
  })

  default = null
}
