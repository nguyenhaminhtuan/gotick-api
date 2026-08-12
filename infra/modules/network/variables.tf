variable "project_id" {
  type = string
}

variable "name" {
  description = "VPC name."
  type        = string
}

variable "region" {
  description = "Region for subnets that do not set their own."
  type        = string
}

variable "routing_mode" {
  description = "REGIONAL keeps routes inside their region. GLOBAL only matters with more than one region."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Must be REGIONAL or GLOBAL."
  }
}

variable "subnets" {
  type = map(object({
    ip_cidr_range            = string
    region                   = optional(string)
    private_ip_google_access = optional(bool, true)
  }))

  default = {}
}

variable "firewall_rules" {
  type = map(object({
    ranges      = list(string)
    protocols   = optional(map(list(string)), { tcp = [] })
    direction   = optional(string, "EGRESS")
    action      = optional(string, "allow")
    priority    = optional(number, 1000)
    target_tags = optional(list(string))
    description = optional(string)

    # Targeting the account a VM runs as, rather than a tag it carries: a tag is
    # something any other VM can attach to itself.
    target_service_accounts = optional(list(string))
  }))

  default = {}

  validation {
    condition = alltrue([
      for r in var.firewall_rules :
      r.target_tags == null || r.target_service_accounts == null
    ])
    error_message = "A rule takes target_tags or target_service_accounts, not both."
  }

  validation {
    condition     = alltrue([for r in var.firewall_rules : contains(["INGRESS", "EGRESS"], r.direction)])
    error_message = "direction must be INGRESS or EGRESS."
  }

  validation {
    condition     = alltrue([for r in var.firewall_rules : contains(["allow", "deny"], r.action)])
    error_message = "action must be allow or deny."
  }
}
