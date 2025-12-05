# Module Outputs
output "tag_database" {
  description = "The tag database name"
  value       = module.snowflake_foundation.tag_database_name
}

output "functional_roles" {
  description = "List of functional roles created"
  value       = module.snowflake_foundation.functional_role_names
}

output "data_access_roles" {
  description = "List of data access roles created"
  value       = module.snowflake_foundation.data_access_role_names
}

output "all_roles" {
  description = "List of all roles created"
  value       = module.snowflake_foundation.all_role_names
}

output "tags_created" {
  description = "Tags created by the module"
  value       = module.snowflake_foundation.tags_created
}

# Example Database Outputs
output "main_database_name" {
  description = "Name of the main database"
  value       = snowflake_database.main.name
}

output "module_configuration_summary" {
  description = "Summary of module configuration"
  value       = module.snowflake_foundation.configuration_summary
} 