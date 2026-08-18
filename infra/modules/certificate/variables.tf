variable "project_id" {
  type = string
}

variable "name" {
  description = <<-EOT
    Base name for the certificate, its map, and the DNS authorizations.

    Changing it replaces all three. The replacement certificate has to provision
    before it serves anything, so treat the name as fixed once the domain is
    live.
  EOT

  type = string
}

variable "domains" {
  description = <<-EOT
    Names on the managed certificate. A wildcard covers one label, so
    *.example.com does not answer for a.b.example.com and that name needs its
    own entry.

    The DNS authorizations are derived from this list rather than given
    separately, since a name authorized nowhere leaves the certificate stuck in
    provisioning.
  EOT

  type = list(string)

  validation {
    condition     = length(var.domains) > 0
    error_message = "At least one domain is required."
  }
}
