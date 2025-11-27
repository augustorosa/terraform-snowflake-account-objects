# =============================================================================
# TERRAFORM MODULE FOR SNOWFLAKE ACCOUNT OBJECTS
# =============================================================================
# Comprehensive single module with feature flags
# This file contains:
# - Local variables and computed values
# - Central settings database and schemas
# - Classification configuration
# =============================================================================

# =============================================================================
# LOCAL VARIABLES AND COMPUTED VALUES
# =============================================================================

locals {
  # Environment prefix mapping
  env_prefix = {
    dev     = "DEV"
    staging = "STG"
    prod    = "PRD"
  }

  # Construct base naming components
  base_prefix = upper("${local.env_prefix[lower(var.environment)]}_${var.project_name}")

  # Tag values with defaults (removed timestamp to prevent plan drift)
  all_tags = merge(
    var.default_tags,
    {
      environment       = var.environment
      project           = var.project_name
      module_version    = var.module_version
      terraform_managed = "true"
    }
  )

  # Central settings database name (for network rules, governance, etc.)
  central_db_name = upper(var.project_name)
  
  # Tag database name (legacy - now uses central database)
  tag_database_name = var.enable_tagging ? "${local.base_prefix}_${upper(var.tag_database_suffix)}_DB" : ""

  # Classification configuration
  classification_enabled      = var.enable_auto_classification
  classification_profile_name = var.enable_auto_classification ? "${local.base_prefix}_CLASSIFICATION_PROFILE" : null
}

# =============================================================================
# CENTRAL SETTINGS DATABASE
# =============================================================================
# Central database for account-level settings including:
# - Network rules and policies
# - Governance configurations
# - Security policies
# - Tag definitions (optional, can migrate from legacy tag_database)
#
# Naming pattern: {PROJECT_NAME} (e.g., "MYPROJECT")
# =============================================================================

resource "snowflake_database" "central_settings" {
  count = var.enable_central_settings_db ? 1 : 0

  name    = local.central_db_name
  comment = "Central settings database for ${var.project_name} - Contains network rules, governance, and security configurations - Managed by Terraform"

  data_retention_time_in_days = var.central_settings_data_retention_days

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# CENTRAL SETTINGS SCHEMAS
# =============================================================================

# NETWORK SCHEMA - For network rules and policies
resource "snowflake_schema" "network_schema" {
  count = var.enable_central_settings_db && var.enable_network_policies ? 1 : 0

  database = snowflake_database.central_settings[0].name
  name     = "NETWORK"
  comment  = "Schema for network rules and policies - Managed by Terraform"

  is_transient        = false
  with_managed_access = true

  lifecycle {
    prevent_destroy = true
  }
}

# GOVERNANCE SCHEMA - For governance configurations
resource "snowflake_schema" "governance_schema" {
  count = var.enable_central_settings_db ? 1 : 0

  database = snowflake_database.central_settings[0].name
  name     = "GOVERNANCE"
  comment  = "Schema for governance configurations and policies - Managed by Terraform"

  is_transient        = false
  with_managed_access = true

  lifecycle {
    prevent_destroy = true
  }
}

# SECURITY SCHEMA - For security policies and configurations
resource "snowflake_schema" "security_schema" {
  count = var.enable_central_settings_db ? 1 : 0

  database = snowflake_database.central_settings[0].name
  name     = "SECURITY"
  comment  = "Schema for security policies and configurations - Managed by Terraform"

  is_transient        = false
  with_managed_access = true

  lifecycle {
    prevent_destroy = true
  }
}

# TAGS SCHEMA - For tag definitions (alternative to legacy tag_database)
resource "snowflake_schema" "tags_schema" {
  count = var.enable_central_settings_db && var.enable_tagging && var.use_central_db_for_tags ? 1 : 0

  database = snowflake_database.central_settings[0].name
  name     = "TAGS"
  comment  = "Schema for tag definitions - Managed by Terraform"

  is_transient        = false
  with_managed_access = true

  lifecycle {
    prevent_destroy = true
  }
}

# AUDIT SCHEMA - For audit logs and compliance tracking
resource "snowflake_schema" "audit_schema" {
  count = var.enable_central_settings_db ? 1 : 0

  database = snowflake_database.central_settings[0].name
  name     = "AUDIT"
  comment  = "Schema for audit logs and compliance tracking - Managed by Terraform"

  is_transient        = false
  with_managed_access = true

  lifecycle {
    prevent_destroy = true
  }
}