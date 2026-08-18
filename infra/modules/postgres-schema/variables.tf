variable "name" {
  type = string
}

variable "database" {
  type = string
}

variable "owner" {
  type = string
}

variable "if_not_exists" {
  description = "Adopts a schema that is already there instead of failing on it."
  type        = bool
  default     = true
}

variable "drop_cascade" {
  description = "Whether destroying the schema takes whatever is inside it along."
  type        = bool
  default     = false
}

variable "grants" {
  type = map(object({
    role        = string
    object_type = string
    privileges  = list(string)
  }))

  default = {}

  validation {
    condition     = alltrue([for g in var.grants : g.role != var.owner])
    error_message = "The owner takes no grant here. Postgres keeps an owner's privileges in the schema's default ACL already, so granting them again only turns them into a resource that gets revoked on destroy — and revoking an owner's own USAGE is allowed, which leaves nothing able to look inside the schema and fails every revoke after it. Terraform orders sibling grants arbitrarily, so that revoke can come first."
  }
}

variable "default_privileges" {
  type = map(object({
    role        = string
    owner       = string
    object_type = string
    privileges  = list(string)
  }))

  default = {}
}
