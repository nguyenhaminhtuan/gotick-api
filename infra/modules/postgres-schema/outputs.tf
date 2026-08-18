output "name" {
  description = "Schema name. Reference this rather than the string it was given, so anything downstream is ordered after the schema."
  value       = postgresql_schema.this.name
}
