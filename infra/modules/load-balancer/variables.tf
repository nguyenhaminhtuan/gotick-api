variable "project_id" {
  type = string
}

variable "name" {
  description = "Base name. Every resource here derives from it, so it also groups them in the console."
  type        = string
}

variable "region" {
  description = "Region of the Cloud Run services the serverless NEGs point at. The load balancer itself is global."
  type        = string
}

variable "backends" {
  description = <<-EOT
    Backends keyed by name, each one a serverless NEG plus the backend service
    in front of it.

    url_mask tells the NEG which Cloud Run service a request belongs to by
    reading it out of the host, so `<service>.example.com` sends api.example.com
    to the service named api and needs no entry per service.

    hosts are the host rules routed to this backend. Exactly one backend leaves
    it empty and becomes the default that answers everything else.

    iap puts Identity-Aware Proxy in front and grants its members
    roles/iap.httpsResourceAccessor. It applies to the whole backend service, so
    anything that must be reached without a sign-in belongs on a different one.
    The Cloud Run service behind it has to name the IAP service agent as an
    invoker, since IAP is what calls it once a user is through.
  EOT

  type = map(object({
    url_mask        = string
    hosts           = optional(list(string), [])
    logging         = optional(bool, false)
    log_sample_rate = optional(number, 1)

    iap = optional(object({
      members = list(string)
    }))
  }))

  validation {
    condition     = length([for b in var.backends : b if length(b.hosts) == 0]) == 1
    error_message = "Exactly one backend must have no hosts, to serve as the url map default."
  }

  validation {
    condition     = alltrue([for b in var.backends : b.iap == null || length(coalesce(try(b.iap.members, null), [])) > 0])
    error_message = "A backend with iap needs at least one member, or nobody can reach it."
  }

  validation {
    condition     = alltrue([for b in var.backends : b.iap == null]) || var.iap != null
    error_message = "A backend with iap needs the iap variable set."
  }
}

variable "iap" {
  description = <<-EOT
    What IAP needs once at the project level, as opposed to the per-backend iap
    block above which says who may pass through. Setting this also creates the
    IAP service agent, since the agent is what calls Cloud Run after a user is
    let through.

    Required as soon as any backend sets iap, because the Google-managed client
    IAP falls back to only serves identities inside a Google Cloud organization.
    A project outside an org, or a member outside it, needs a client of its own.

    Create the client under APIs & Services > Credentials > OAuth client ID >
    Web application, then add the URI IAP signs users back to:

      https://iap.googleapis.com/v1/oauth/clientIds/<client-id>:handleRedirect

    Console only. google_iap_brand and google_iap_client create internal brands,
    which a project outside an organization cannot have.

    Kept out of the backends map so that map stays free of sensitive values and
    can still be used as a for_each key.
  EOT

  type = object({
    oauth_client_id     = string
    oauth_client_secret = string
  })

  default   = null
  sensitive = true
}

variable "certificate_domains" {
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
    condition     = length(var.certificate_domains) > 0
    error_message = "At least one domain is required."
  }
}

variable "keep_alive_timeout" {
  description = "Seconds the proxy holds an idle client connection. Google's default is 610."
  type        = number
  default     = 120
}

variable "http_redirect" {
  description = "Serves port 80 with a 301 to the same URL over HTTPS."
  type        = bool
  default     = true
}
