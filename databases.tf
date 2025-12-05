# =============================================================================
# DATABASE INFRASTRUCTURE (3-LAYER ARCHITECTURE)
# =============================================================================

locals {
  # Flatten databases with their schemas for easier processing
  database_schemas = var.enable_databases ? merge([
    for db_key, db_config in var.databases : {
      for schema_type in(db_config.enable_3_layer_architecture ? ["RAW", "PREPARE", "ANALYSIS"] : []) :
      "${db_key}_${schema_type}" => {
        database_key    = db_key
        database_config = db_config
        schema_name     = schema_type
        schema_config = (
          schema_type == "RAW" ? {
            comment   = "Raw data layer - unprocessed source data"
            managed   = false
            transient = false
          } :
          schema_type == "PREPARE" ? {
            comment   = "Prepare data layer - cleaned and transformed data"
            managed   = db_config.prepare_layer_managed_access
            transient = db_config.prepare_layer_transient
          } :
          schema_type == "ANALYSIS" ? {
            comment   = "Analyze data layer - business-ready data for reporting and analytics"
            managed   = db_config.analysis_layer_managed_access
            transient = false
          } : {}
        )
      }
    }
  ]...) : {}

  # Flatten custom schemas
  custom_schemas = var.enable_databases ? merge([
    for db_key, db_config in var.databases : {
      for schema_key, schema_config in db_config.custom_schemas :
      "${db_key}_${schema_key}" => {
        database_key    = db_key
        database_config = db_config
        schema_name     = schema_config.name
        schema_config   = schema_config
      }
    }
  ]...) : {}

  # Combine all schemas
  all_schemas = merge(local.database_schemas, local.custom_schemas)
}

# Create databases
resource "snowflake_database" "databases" {
  for_each = var.enable_databases ? var.databases : {}

  # Naming per ARCHITECTURE.md Section 9.1 - Multi-Database Approach:
  # Pattern: {ENV}_{LAYER} (e.g., DEV_RAW, QA_ANL, PROD_INT)
  # Layers: RAW (raw data), ANL (analysis), INT (integration)
  name    = each.value.suffix != "" ? "${local.env_prefix[lower(var.environment)]}_${upper(each.value.suffix)}" : "${local.env_prefix[lower(var.environment)]}_${upper(each.key)}"
  comment = coalesce(each.value.comment, "Database for ${var.project_name} ${var.environment} - Managed by Terraform")

  # Data retention configuration
  data_retention_time_in_days = each.value.data_retention_days

  # Optional external volume for Iceberg tables
  external_volume = each.value.external_volume != "" ? each.value.external_volume : null

  # Catalog integration for Iceberg
  catalog = each.value.catalog_integration != "" ? each.value.catalog_integration : null

  # Console output and logging
  enable_console_output = each.value.enable_console_output
  log_level             = each.value.log_level
  trace_level           = each.value.trace_level

  lifecycle {
    prevent_destroy = true # Prevent accidental deletion of databases
  }
}

# Create schemas for databases
resource "snowflake_schema" "schemas" {
  for_each = local.all_schemas

  database = snowflake_database.databases[each.value.database_key].name
  name     = each.value.schema_name
  comment  = each.value.schema_config.comment

  # Managed access configuration
  with_managed_access = each.value.schema_config.managed

  # Transient configuration
  is_transient = each.value.schema_config.transient

  # Data retention (inherits from database if not specified)
  data_retention_time_in_days = lookup(each.value.schema_config, "data_retention_days", null)

  # Advanced schema configuration
  enable_console_output = each.value.database_config.enable_console_output
  log_level             = each.value.database_config.log_level
  trace_level           = each.value.database_config.trace_level

  # External volume and catalog (for Iceberg)
  external_volume = each.value.database_config.external_volume != "" ? each.value.database_config.external_volume : null
  catalog         = each.value.database_config.catalog_integration != "" ? each.value.database_config.catalog_integration : null
}

# Create layer information views
resource "snowflake_view" "layer_info_views" {
  for_each = var.enable_databases ? {
    for key, schema in local.database_schemas :
    key => schema
    if schema.database_config.create_layer_info_views
  } : {}

  database = snowflake_database.databases[each.value.database_key].name
  schema   = snowflake_schema.schemas[each.key].name
  name     = "_LAYER_INFO"

  comment = "Information view for ${each.value.schema_name} layer"

  statement = <<-SQL
    SELECT 
      '${each.value.schema_name}' AS layer_name,
      '${each.value.schema_config.comment}' AS layer_description,
      CURRENT_DATABASE() AS database_name,
      CURRENT_SCHEMA() AS schema_name,
      CURRENT_TIMESTAMP() AS view_created_at,
      '${var.module_version}' AS module_version
  SQL

  is_secure = false
}
