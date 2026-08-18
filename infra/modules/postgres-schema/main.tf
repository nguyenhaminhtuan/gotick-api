terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
}

resource "postgresql_schema" "this" {
  name     = var.name
  database = var.database
  owner    = var.owner

  if_not_exists = var.if_not_exists
  drop_cascade  = var.drop_cascade
}

resource "postgresql_grant" "this" {
  for_each = var.grants

  role        = each.value.role
  database    = var.database
  schema      = postgresql_schema.this.name
  object_type = each.value.object_type
  privileges  = each.value.privileges
}

resource "postgresql_default_privileges" "this" {
  for_each = var.default_privileges

  role     = each.value.role
  database = var.database
  schema   = postgresql_schema.this.name
  owner    = each.value.owner

  object_type = each.value.object_type
  privileges  = each.value.privileges
}
