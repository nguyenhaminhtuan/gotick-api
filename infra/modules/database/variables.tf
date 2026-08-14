variable "project_id" {
  type = string
}

variable "name" {
  description = "Instance name. Cloud SQL refuses to reuse it for about a week after a delete."
  type        = string
}

variable "region" {
  type = string
}

variable "network" {
  description = "VPC self link or id the peering is created on."
  type        = string
}

variable "database_version" {
  type    = string
  default = "POSTGRES_18"
}

variable "tier" {
  description = "Machine type and edition together. See the tiers map in main.tf for what each key resolves to."
  type        = string

  validation {
    condition     = contains(keys(local.tiers), var.tier)
    error_message = format("Must be one of: %s.", join(", ", keys(local.tiers)))
  }
}

variable "disk_size" {
  description = "GB. A floor rather than a limit while disk_autoresize is on."
  type        = number
  default     = 10
}

variable "activation_policy" {
  description = "NEVER stops the instance without deleting it: data, private IP and configuration all survive, and only compute stops billing."
  type        = string
  default     = "ALWAYS"

  validation {
    condition     = contains(["ALWAYS", "NEVER", "ON_DEMAND"], var.activation_policy)
    error_message = "Must be ALWAYS, NEVER or ON_DEMAND."
  }
}

variable "high_availability" {
  description = "Regional, with a standby in a second zone. The standby shares the primary's IP, so a failover changes nothing for clients."
  type        = bool
  default     = false
}

variable "read_pool" {
  description = <<-EOT
    Read pool nodes sitting behind one endpoint that spreads connections across
    them. Takes 1 to 20 nodes, and only a pool of two or more is covered by the
    SLA. tier defaults to the primary's.

    Routing ignores replication lag, and two statements in one session can land
    on nodes at different positions, so a read here can return an older state
    than a read a moment earlier. Anything that has to observe its own write
    belongs on the primary.
  EOT

  type = object({
    node_count = number
    tier       = optional(string)
  })

  default = null

  validation {
    condition     = var.read_pool == null || try(var.read_pool.node_count, 0) >= 1 && try(var.read_pool.node_count, 0) <= 20
    error_message = "node_count must be between 1 and 20."
  }

  validation {
    condition     = var.read_pool == null || try(local.tiers[var.tier].edition, null) == "ENTERPRISE_PLUS"
    error_message = "A read pool requires an enterprise-plus tier on the primary."
  }
}

variable "peering_range_address" {
  description = "First address of the range handed to Google."
  type        = string
}

variable "peering_range_prefix_length" {
  description = "Google recommends 16; the minimum accepted is 24. The range is consumed from your address plan and cannot be resized afterwards."
  type        = number
  default     = 16
}

variable "ssl_mode" {
  description = "encrypted-only rejects plaintext without requiring a client certificate."
  type        = string
  default     = "encrypted-only"

  validation {
    condition     = contains(keys(local.ssl_mode), var.ssl_mode)
    error_message = format("Must be one of: %s.", join(", ", keys(local.ssl_mode)))
  }
}

variable "database_name" {
  type = string
}

variable "users" {
  description = <<-EOT
    Database users keyed by name.

    An empty type means a built-in user authenticating with a password, and then
    password_version is the counter that decides when that password is sent.
    type = CLOUD_IAM_SERVICE_ACCOUNT means it logs in with an IAM token and has
    no password at all.

    The distinction matters beyond syntax: Cloud SQL grants cloudsqlsuperuser to
    built-in users created through the API, and grants nothing to IAM users. So
    database_roles is how an IAM user gets anything at all, and is no help at
    stopping a built-in one from being a superuser: an empty list reads the same
    as an unset one at create time, and only a later change to the list revokes
    what Cloud SQL already granted.

    Anything that must hold exactly the privileges it is given, and nothing else,
    belongs in a postgresql_role rather than here.
  EOT

  type = map(object({
    type             = optional(string)
    password_version = optional(number)
    database_roles   = optional(list(string))
  }))

  default = {}

  validation {
    condition = alltrue([
      for name, u in var.users :
      u.type == null || u.type == "CLOUD_IAM_SERVICE_ACCOUNT" || u.type == "CLOUD_IAM_USER"
    ])
    error_message = "type must be null, CLOUD_IAM_SERVICE_ACCOUNT or CLOUD_IAM_USER."
  }

  validation {
    condition = alltrue([
      for name, u in var.users :
      u.type != null || u.password_version != null
    ])
    error_message = "A built-in user needs password_version."
  }
}

variable "user_passwords" {
  description = <<-EOT
    Passwords keyed by the same names as users, for built-in users only.
    Write-only, so a password reaches the API without passing through state or a
    plan file, and is sent only on the applies where that user's counter changes.
  EOT

  type      = map(string)
  default   = {}
  ephemeral = true

  validation {
    condition = alltrue([
      for name, u in var.users :
      u.type != null || contains(keys(var.user_passwords), name)
    ])
    error_message = "Every built-in user needs a password of the same key."
  }
}

variable "connection_pool" {
  description = <<-EOT
    Managed Connection Pooling. Clients reach the pooler on port 6432 and the
    database directly on 5432. In transaction mode a session does not survive a
    statement, so SET, LISTEN, PREPARE and session advisory locks require 5432.
  EOT

  type = object({
    enabled = optional(bool, true)
    flags   = optional(map(string), {})
  })

  default = null

  validation {
    condition     = var.connection_pool == null || try(local.tiers[var.tier].edition, null) == "ENTERPRISE_PLUS"
    error_message = "Managed Connection Pooling runs on Enterprise Plus only, so tier must be an enterprise-plus-* key."
  }
}

variable "maintenance_window" {
  description = <<-EOT
    Null lets Google restart the instance for maintenance at any time. hour is
    0-23 UTC, and the window applies to the read replicas as well.
  EOT

  type = object({
    day          = string
    hour         = number
    update_track = optional(string, "stable")
  })

  default = null

  validation {
    condition     = var.maintenance_window == null || contains(keys(local.maintenance_day), try(var.maintenance_window.day, ""))
    error_message = format("day must be one of: %s.", join(", ", keys(local.maintenance_day)))
  }

  validation {
    condition     = var.maintenance_window == null || try(var.maintenance_window.hour, -1) >= 0 && try(var.maintenance_window.hour, -1) <= 23
    error_message = "hour must be 0-23."
  }

  validation {
    condition     = var.maintenance_window == null || contains(local.update_track, try(var.maintenance_window.update_track, ""))
    error_message = format("update_track must be one of: %s.", join(", ", local.update_track))
  }
}

variable "password_policy" {
  description = <<-EOT
    Rules the instance enforces when a built-in user's password is set. Null
    turns the policy off.

    min_length tops out at 30, which is Cloud SQL's own ceiling.

    complexity is unset by default: COMPLEXITY_DEFAULT demands a
    non-alphanumeric character, which every consumer carrying the password
    inside a connection URL then has to percent-encode. Length carries the
    entropy instead.

    password_change_interval is unset for a different reason: it refuses a
    second change within the interval, which is precisely the situation a leak
    puts you in.
  EOT

  type = object({
    min_length                  = optional(number, 30)
    reuse_interval              = optional(number, 5)
    disallow_username_substring = optional(bool, true)
    complexity                  = optional(string)
    password_change_interval    = optional(string)
  })

  default = {}

  validation {
    condition     = try(var.password_policy.min_length, 0) <= 30
    error_message = "Cloud SQL caps min_length at 30, and rejects the instance rather than the policy when it is higher."
  }
}

variable "database_flags" {
  description = "Instance-level Postgres flags."
  type        = map(string)
  default     = {}
}

variable "query_insights" {
  type = object({
    query_plans_per_minute  = optional(number, 5)
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, false)
    record_client_address   = optional(bool, false)
  })

  default = null

  validation {
    condition     = var.query_insights == null || (try(var.query_insights.query_plans_per_minute, 5) >= 0 && try(var.query_insights.query_plans_per_minute, 5) <= 20)
    error_message = "query_plans_per_minute must be 0-20."
  }

  validation {
    condition     = var.query_insights == null || (try(var.query_insights.query_string_length, 1024) >= 256 && try(var.query_insights.query_string_length, 1024) <= 4500)
    error_message = "query_string_length must be 256-4500 bytes."
  }
}

variable "backup_start_time" {
  description = "HH:MM UTC."
  type        = string
  default     = "17:00"
}

variable "retained_backups" {
  type    = number
  default = 30
}

variable "point_in_time_recovery" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "public_ip" {
  description = "Adds a public IP alongside the private one. Off means the instance is reachable only over the peering."
  type        = bool
  default     = false
}

variable "disk_autoresize" {
  description = "Grows the disk when it fills. Off means a full disk stops writes."
  type        = bool
  default     = true
}

variable "backup_enabled" {
  type    = bool
  default = true
}

