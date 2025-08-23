# Module Outputs
output "naming_prefix" {
  description = "The naming prefix used for all resources"
  value       = module.snowflake_foundation.naming_prefix
}

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

output "governance_tags" {
  description = "Governance tags created"
  value       = module.snowflake_foundation.governance_tags
}

# Example Database Outputs
output "main_database_name" {
  description = "Name of the main database"
  value       = snowflake_database.main.name
}

output "validation_procedure" {
  description = "Naming validation procedure details"
  value       = module.snowflake_foundation.naming_validation_procedure
}

# Usage Examples
output "naming_examples" {
  description = "Examples of properly named resources"
  value = {
    database  = "${module.snowflake_foundation.naming_prefix}_DB_<NAME>"
    schema    = "${module.snowflake_foundation.naming_prefix}_SCH_<NAME>"
    warehouse = "${module.snowflake_foundation.naming_prefix}_WH_<NAME>"
    role      = "${module.snowflake_foundation.naming_prefix}_ROLE_<NAME>"
    user      = "${module.snowflake_foundation.naming_prefix}_USER_<NAME>"
  }
}

output "role_usage_examples" {
  description = "Examples of how to assign roles to users"
  value = {
    business_analyst = [
      "GRANT ROLE ${module.snowflake_foundation.functional_role_names[0]} TO USER analyst_jane;",
      "GRANT ROLE ${module.snowflake_foundation.data_access_role_names[1]} TO USER analyst_jane;"
    ]
    data_engineer = [
      "GRANT ROLE ${module.snowflake_foundation.functional_role_names[1]} TO USER engineer_john;",
      "GRANT ROLE ${module.snowflake_foundation.data_access_role_names[0]} TO USER engineer_john;"
    ]
    etl_tool = [
      "GRANT ROLE ${module.snowflake_foundation.functional_role_names[1]} TO USER fivetran_service;",
      "GRANT ROLE ${module.snowflake_foundation.data_access_role_names[2]} TO USER fivetran_service;"
    ]
  }
} 