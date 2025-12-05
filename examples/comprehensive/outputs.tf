# =============================================================================
# OUTPUTS - Comprehensive Example
# =============================================================================

# -----------------------------------------------------------------------------
# Module Summary
# -----------------------------------------------------------------------------

output "deployment_info" {
  description = "Deployment information"
  value = {
    project     = var.project_name
    environment = var.environment
    team        = var.team_name
    features_enabled = {
      rbac                = true
      tagging             = true
      databases           = true
      warehouses          = true
      data_loading        = true
      resource_monitors   = true
      network_policies    = var.enable_network_policies
      central_settings_db = true
    }
  }
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "databases" {
  description = "Created databases with their schemas"
  value       = module.snowflake_account_objects.databases
}

output "schemas" {
  description = "Created schemas organized by layer"
  value       = module.snowflake_account_objects.schemas
}

# -----------------------------------------------------------------------------
# Warehouse Outputs
# -----------------------------------------------------------------------------

output "warehouses" {
  description = "Created warehouses"
  value       = module.snowflake_account_objects.warehouses
}

# -----------------------------------------------------------------------------
# RBAC Outputs
# -----------------------------------------------------------------------------

output "functional_roles" {
  description = "Created functional roles"
  value       = module.snowflake_account_objects.functional_roles
}

output "data_access_roles" {
  description = "Created data access roles"
  value       = module.snowflake_account_objects.data_access_roles
}

output "custom_roles" {
  description = "Created custom functional roles"
  value       = module.snowflake_account_objects.custom_roles
}

# -----------------------------------------------------------------------------
# Tagging Outputs
# -----------------------------------------------------------------------------

# Note: tag_database and governance_tags outputs are not available in the module
# Use tag_associations_summary instead for tagging information

output "tag_associations_summary" {
  description = "Summary of applied tag associations"
  value       = module.snowflake_account_objects.tag_associations_summary
}

# -----------------------------------------------------------------------------
# Central Settings Outputs
# -----------------------------------------------------------------------------

output "central_settings_database" {
  description = "Central settings database with schemas"
  value       = module.snowflake_account_objects.central_settings_database
}

# -----------------------------------------------------------------------------
# Resource Monitor Outputs
# -----------------------------------------------------------------------------

output "resource_monitors" {
  description = "Created resource monitors"
  value       = module.snowflake_account_objects.resource_monitors
}

# -----------------------------------------------------------------------------
# Network Policy Outputs (if enabled)
# -----------------------------------------------------------------------------

output "network_rules" {
  description = "Created network rules"
  value       = var.enable_network_policies ? module.snowflake_account_objects.network_rules : {}
}

output "network_policies" {
  description = "Created network policies"
  value       = var.enable_network_policies ? module.snowflake_account_objects.network_policies : {}
}

# -----------------------------------------------------------------------------
# Data Loading Outputs
# -----------------------------------------------------------------------------

output "stages" {
  description = "Created stages"
  value       = module.snowflake_account_objects.stages
}

output "file_formats" {
  description = "Created file formats"
  value       = module.snowflake_account_objects.file_formats
}

# -----------------------------------------------------------------------------
# Naming Convention Reference
# -----------------------------------------------------------------------------

output "naming_convention" {
  description = "Naming convention used for resources"
  value = {
    prefix_pattern = "ENV_PROJECT"
    example        = "${upper(substr(var.environment, 0, 3))}_${upper(var.project_name)}"
    databases      = "${upper(substr(var.environment, 0, 3))}_${upper(var.project_name)}_*_DB"
    warehouses     = "${upper(substr(var.environment, 0, 3))}_${upper(var.project_name)}_*_WH"
    roles          = "${upper(substr(var.environment, 0, 3))}_${upper(var.project_name)}_*_ROLE"
  }
}
