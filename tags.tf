# =============================================================================
# TAGGING INFRASTRUCTURE
# =============================================================================
# This file contains:
# 1. Tag database and schema creation
# 2. Tag definitions (governance, operational, technical)
# 3. Tag associations (auto-apply tags to resources)
# =============================================================================

# =============================================================================
# LOCALS FOR TAG DATABASE/SCHEMA SELECTION
# =============================================================================

locals {
  # Use central database if enabled, otherwise use legacy tag database
  tag_database = var.enable_tagging && var.create_tag_schema ? (
    var.use_central_db_for_tags && var.enable_central_settings_db
    ? snowflake_database.central_settings[0].name
    : snowflake_database.tag_database[0].name
  ) : null

  tag_schema = var.enable_tagging && var.create_tag_schema ? (
    var.use_central_db_for_tags && var.enable_central_settings_db
    ? snowflake_schema.tags_schema[0].name
    : snowflake_schema.tag_schema[0].name
  ) : null
}

# =============================================================================
# TAG DATABASE AND SCHEMA (Legacy - if not using central database)
# =============================================================================

# Create a database for tags (legacy - if not using central database)
resource "snowflake_database" "tag_database" {
  count = var.enable_tagging && var.create_tag_schema && !var.use_central_db_for_tags ? 1 : 0

  name    = local.tag_database_name
  comment = "Database for storing tag definitions - Managed by Terraform"

  data_retention_time_in_days = 1

  lifecycle {
    prevent_destroy = true
  }
}

# Create schema for tags (legacy - if not using central database)
resource "snowflake_schema" "tag_schema" {
  count = var.enable_tagging && var.create_tag_schema && !var.use_central_db_for_tags ? 1 : 0

  database = snowflake_database.tag_database[0].name
  name     = "TAG_DEFINITIONS"
  comment  = "Schema for tag definitions - Managed by Terraform"

  is_transient = false

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# TAG DEFINITIONS
# =============================================================================

# Create governance tags
resource "snowflake_tag" "governance_tags" {
  for_each = var.enable_tagging && var.create_tag_schema ? toset(var.tag_categories.governance.tags) : toset([])

  database = local.tag_database
  schema   = local.tag_schema
  name     = upper(each.key)

  allowed_values = (
    each.key == "environment" ? ["DEV", "STAGING", "PROD"] :
    each.key == "data_classification" ? ["PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"] :
    null
  )

  comment = "Governance tag: ${each.key} - Managed by Terraform"
}

# Create operational tags
resource "snowflake_tag" "operational_tags" {
  for_each = var.enable_tagging && var.create_tag_schema ? toset(var.tag_categories.operational.tags) : toset([])

  database = local.tag_database
  schema   = local.tag_schema
  name     = upper(each.key)

  comment = "Operational tag: ${each.key} - Managed by Terraform"
}

# Create technical tags
resource "snowflake_tag" "technical_tags" {
  for_each = var.enable_tagging && var.create_tag_schema ? toset(var.tag_categories.technical.tags) : toset([])

  database = local.tag_database
  schema   = local.tag_schema
  name     = upper(each.key)

  comment = "Technical tag: ${each.key} - Managed by Terraform"
}

# =============================================================================
# TAG ASSOCIATIONS - DATABASE
# =============================================================================

# Apply environment tag to databases
resource "snowflake_tag_association" "database_environment" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_databases && var.create_tag_schema ? var.databases : {}

  object_identifiers = [snowflake_database.databases[each.key].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.governance_tags["environment"].fully_qualified_name
  tag_value          = upper(var.environment)
}

# Apply project tag to databases
resource "snowflake_tag_association" "database_project" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_databases && var.create_tag_schema ? var.databases : {}

  object_identifiers = [snowflake_database.databases[each.key].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.governance_tags["project"].fully_qualified_name
  tag_value          = var.project_name
}

# Apply terraform_managed tag to databases
resource "snowflake_tag_association" "database_terraform_managed" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_databases && var.create_tag_schema ? var.databases : {}

  object_identifiers = [snowflake_database.databases[each.key].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.technical_tags["terraform_managed"].fully_qualified_name
  tag_value          = "true"
}

# Apply module_version tag to databases
resource "snowflake_tag_association" "database_module_version" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_databases && var.create_tag_schema ? var.databases : {}

  object_identifiers = [snowflake_database.databases[each.key].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.technical_tags["module_version"].fully_qualified_name
  tag_value          = var.module_version
}

# =============================================================================
# TAG ASSOCIATIONS - WAREHOUSE
# =============================================================================

# Apply environment tag to warehouses
resource "snowflake_tag_association" "warehouse_environment" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_warehouses && var.create_tag_schema ? var.warehouses : {}

  object_identifiers = [snowflake_warehouse.warehouses[each.key].fully_qualified_name]
  object_type        = "WAREHOUSE"
  tag_id             = snowflake_tag.governance_tags["environment"].fully_qualified_name
  tag_value          = upper(var.environment)
}

# Apply project tag to warehouses
resource "snowflake_tag_association" "warehouse_project" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_warehouses && var.create_tag_schema ? var.warehouses : {}

  object_identifiers = [snowflake_warehouse.warehouses[each.key].fully_qualified_name]
  object_type        = "WAREHOUSE"
  tag_id             = snowflake_tag.governance_tags["project"].fully_qualified_name
  tag_value          = var.project_name
}

# Apply terraform_managed tag to warehouses
resource "snowflake_tag_association" "warehouse_terraform_managed" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_warehouses && var.create_tag_schema ? var.warehouses : {}

  object_identifiers = [snowflake_warehouse.warehouses[each.key].fully_qualified_name]
  object_type        = "WAREHOUSE"
  tag_id             = snowflake_tag.technical_tags["terraform_managed"].fully_qualified_name
  tag_value          = "true"
}

# =============================================================================
# TAG ASSOCIATIONS - SCHEMA
# =============================================================================

# Apply environment tag to schemas
resource "snowflake_tag_association" "schema_environment" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_databases && var.create_tag_schema ? local.all_schemas : {}

  object_identifiers = [snowflake_schema.schemas[each.key].fully_qualified_name]
  object_type        = "SCHEMA"
  tag_id             = snowflake_tag.governance_tags["environment"].fully_qualified_name
  tag_value          = upper(var.environment)
}

# Apply project tag to schemas
resource "snowflake_tag_association" "schema_project" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_databases && var.create_tag_schema ? local.all_schemas : {}

  object_identifiers = [snowflake_schema.schemas[each.key].fully_qualified_name]
  object_type        = "SCHEMA"
  tag_id             = snowflake_tag.governance_tags["project"].fully_qualified_name
  tag_value          = var.project_name
}

# Apply data_classification tag based on schema layer
resource "snowflake_tag_association" "schema_data_classification" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_databases && var.create_tag_schema ? {
    for k, v in local.database_schemas : k => v
  } : {}

  object_identifiers = [snowflake_schema.schemas[each.key].fully_qualified_name]
  object_type        = "SCHEMA"
  tag_id             = snowflake_tag.governance_tags["data_classification"].fully_qualified_name
  tag_value = (
    each.value.schema_name == "RAW" ? "INTERNAL" :
    each.value.schema_name == "PREPARE" ? "INTERNAL" :
    each.value.schema_name == "ANALYSIS" ? "CONFIDENTIAL" :
    "INTERNAL"
  )
}

# =============================================================================
# TAG ASSOCIATIONS - ROLE
# =============================================================================

# Apply environment tag to functional roles
resource "snowflake_tag_association" "role_environment" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_rbac && var.create_default_roles && var.create_tag_schema ? toset([
    "READER", "WRITER", "ADMIN"
  ]) : toset([])

  object_identifiers = [snowflake_account_role.functional_roles[each.key].fully_qualified_name]
  object_type        = "ROLE"
  tag_id             = snowflake_tag.governance_tags["environment"].fully_qualified_name
  tag_value          = upper(var.environment)
}

# Apply project tag to functional roles
resource "snowflake_tag_association" "role_project" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_rbac && var.create_default_roles && var.create_tag_schema ? toset([
    "READER", "WRITER", "ADMIN"
  ]) : toset([])

  object_identifiers = [snowflake_account_role.functional_roles[each.key].fully_qualified_name]
  object_type        = "ROLE"
  tag_id             = snowflake_tag.governance_tags["project"].fully_qualified_name
  tag_value          = var.project_name
}

# Apply terraform_managed tag to functional roles
resource "snowflake_tag_association" "role_terraform_managed" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_rbac && var.create_default_roles && var.create_tag_schema ? toset([
    "READER", "WRITER", "ADMIN"
  ]) : toset([])

  object_identifiers = [snowflake_account_role.functional_roles[each.key].fully_qualified_name]
  object_type        = "ROLE"
  tag_id             = snowflake_tag.technical_tags["terraform_managed"].fully_qualified_name
  tag_value          = "true"
}

# =============================================================================
# TAG ASSOCIATIONS - CENTRAL SETTINGS DATABASE
# =============================================================================

# Apply environment tag to central settings database
resource "snowflake_tag_association" "central_db_environment" {
  count = var.enable_tagging && var.auto_apply_tags && var.enable_central_settings_db && var.create_tag_schema ? 1 : 0

  object_identifiers = [snowflake_database.central_settings[0].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.governance_tags["environment"].fully_qualified_name
  tag_value          = upper(var.environment)
}

# Apply project tag to central settings database
resource "snowflake_tag_association" "central_db_project" {
  count = var.enable_tagging && var.auto_apply_tags && var.enable_central_settings_db && var.create_tag_schema ? 1 : 0

  object_identifiers = [snowflake_database.central_settings[0].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.governance_tags["project"].fully_qualified_name
  tag_value          = var.project_name
}

# Apply terraform_managed tag to central settings database
resource "snowflake_tag_association" "central_db_terraform_managed" {
  count = var.enable_tagging && var.auto_apply_tags && var.enable_central_settings_db && var.create_tag_schema ? 1 : 0

  object_identifiers = [snowflake_database.central_settings[0].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.technical_tags["terraform_managed"].fully_qualified_name
  tag_value          = "true"
}

# Apply data_classification tag to central settings database (RESTRICTED for security)
resource "snowflake_tag_association" "central_db_data_classification" {
  count = var.enable_tagging && var.auto_apply_tags && var.enable_central_settings_db && var.create_tag_schema ? 1 : 0

  object_identifiers = [snowflake_database.central_settings[0].fully_qualified_name]
  object_type        = "DATABASE"
  tag_id             = snowflake_tag.governance_tags["data_classification"].fully_qualified_name
  tag_value          = "RESTRICTED"
}

# =============================================================================
# TAG ASSOCIATIONS - SERVICE USERS
# =============================================================================

# Apply environment tag to service users
resource "snowflake_tag_association" "service_user_environment" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_key_pair_auth && var.create_tag_schema ? var.service_users : {}

  object_identifiers = [snowflake_service_user.service_users[each.key].fully_qualified_name]
  object_type        = "USER"
  tag_id             = snowflake_tag.governance_tags["environment"].fully_qualified_name
  tag_value          = upper(var.environment)
}

# Apply project tag to service users
resource "snowflake_tag_association" "service_user_project" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_key_pair_auth && var.create_tag_schema ? var.service_users : {}

  object_identifiers = [snowflake_service_user.service_users[each.key].fully_qualified_name]
  object_type        = "USER"
  tag_id             = snowflake_tag.governance_tags["project"].fully_qualified_name
  tag_value          = var.project_name
}

# Apply terraform_managed tag to service users
resource "snowflake_tag_association" "service_user_terraform_managed" {
  for_each = var.enable_tagging && var.auto_apply_tags && var.enable_key_pair_auth && var.create_tag_schema ? var.service_users : {}

  object_identifiers = [snowflake_service_user.service_users[each.key].fully_qualified_name]
  object_type        = "USER"
  tag_id             = snowflake_tag.technical_tags["terraform_managed"].fully_qualified_name
  tag_value          = "true"
}