output "instance_name" {
  value = google_sql_database_instance.this.name
}

output "connection_name" {
  value = google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  description = "Unchanged by an HA failover."
  value       = google_sql_database_instance.this.private_ip_address
}

output "database_name" {
  value = google_sql_database.this.name
}

output "read_pool_private_ip_address" {
  description = "The pool's single endpoint. Null when no read pool is configured."
  value       = try(google_sql_database_instance.read_pool[0].private_ip_address, null)
}
