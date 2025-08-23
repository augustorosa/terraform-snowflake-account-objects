# Terraform Module for Snowflake Account Objects
# Comprehensive single module with feature flags

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

  # Tag values with defaults
  all_tags = merge(
    var.default_tags,
    {
      environment       = var.environment
      project           = var.project_name
      module_version    = "1.0.0"
      terraform_managed = "true"
      created_date      = timestamp()
    }
  )

  # Tag database name
  tag_database_name = var.enable_tagging ? "${local.base_prefix}_${upper(var.tag_database_suffix)}_DB" : ""
  
  # Generate timestamp for unique naming
  timestamp_suffix = formatdate("YYYYMMDD", timestamp())
}

# =============================================================================
# TAGGING INFRASTRUCTURE
# =============================================================================

# Create a database for tags (if enabled)
resource "snowflake_database" "tag_database" {
  count = var.enable_tagging && var.create_tag_schema ? 1 : 0

  name    = local.tag_database_name
  comment = "Database for storing tag definitions - Managed by Terraform"

  data_retention_time_in_days = 1
}

# Create schema for tags
resource "snowflake_schema" "tag_schema" {
  count = var.enable_tagging && var.create_tag_schema ? 1 : 0

  database = snowflake_database.tag_database[0].name
  name     = "TAG_DEFINITIONS"
  comment  = "Schema for tag definitions - Managed by Terraform"

  is_transient = false
}

# Create governance tags
resource "snowflake_tag" "governance_tags" {
  for_each = var.enable_tagging && var.create_tag_schema ? toset(var.tag_categories.governance.tags) : toset([])

  database = snowflake_database.tag_database[0].name
  schema   = snowflake_schema.tag_schema[0].name
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

  database = snowflake_database.tag_database[0].name
  schema   = snowflake_schema.tag_schema[0].name
  name     = upper(each.key)

  comment = "Operational tag: ${each.key} - Managed by Terraform"
}

# Create technical tags
resource "snowflake_tag" "technical_tags" {
  for_each = var.enable_tagging && var.create_tag_schema ? toset(var.tag_categories.technical.tags) : toset([])

  database = snowflake_database.tag_database[0].name
  schema   = snowflake_schema.tag_schema[0].name
  name     = upper(each.key)

  comment = "Technical tag: ${each.key} - Managed by Terraform"
}

# =============================================================================
# RBAC (ROLE-BASED ACCESS CONTROL)
# =============================================================================

# Create functional roles (what you can DO)
resource "snowflake_account_role" "functional_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "READER",    # Can read data
    "WRITER",    # Can read and write data  
    "ADMIN"      # Can read, write, and administer
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_ROLE"
  comment = "Functional role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# Create data access roles (what data you can access)
resource "snowflake_account_role" "data_access_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "ALL_DATA",      # Access to RAW, PREPARE, ANALYZE
    "ANALYZE_ONLY",  # Access to ANALYZE layer only
    "INGEST_ONLY"    # Access to RAW layer only (for ingestion)
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_ROLE"
  comment = "Data access role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# Create custom functional roles
resource "snowflake_account_role" "custom_functional_roles" {
  for_each = var.enable_rbac ? var.custom_functional_roles : {}

  name    = "${local.base_prefix}_${upper(each.key)}_ROLE"
  comment = each.value.comment != "" ? each.value.comment : "Custom functional role: ${each.key} - Managed by Terraform"
}

# Create custom data access roles
resource "snowflake_account_role" "custom_data_access_roles" {
  for_each = var.enable_rbac ? var.custom_data_access_roles : {}

  name    = "${local.base_prefix}_${upper(each.key)}_DATA_ROLE"
  comment = each.value.comment != "" ? each.value.comment : "Custom data access role: ${each.key} - Managed by Terraform"
}

# Grant ADMIN role to SYSADMIN (SYSADMIN inherits ADMIN)
resource "snowflake_grant_account_role" "admin_to_sysadmin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = "${local.base_prefix}_ADMIN_ROLE"
  parent_role_name = "SYSADMIN"
}

# Create proper inheritance chain: READER -> WRITER -> ADMIN
resource "snowflake_grant_account_role" "writer_inherits_reader" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = "${local.base_prefix}_WRITER_ROLE"
  parent_role_name = "${local.base_prefix}_READER_ROLE"
}

resource "snowflake_grant_account_role" "admin_inherits_writer" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = "${local.base_prefix}_ADMIN_ROLE"
  parent_role_name = "${local.base_prefix}_WRITER_ROLE"
}

# Grant data access roles to ADMIN (ADMIN gets all data access)
resource "snowflake_grant_account_role" "all_data_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = "${local.base_prefix}_ALL_DATA_ROLE"
  parent_role_name = "${local.base_prefix}_ADMIN_ROLE"
}

resource "snowflake_grant_account_role" "analyze_only_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = "${local.base_prefix}_ANALYZE_ONLY_ROLE"
  parent_role_name = "${local.base_prefix}_ADMIN_ROLE"
}

resource "snowflake_grant_account_role" "ingest_only_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = "${local.base_prefix}_INGEST_ONLY_ROLE"
  parent_role_name = "${local.base_prefix}_ADMIN_ROLE"
}

# =============================================================================
# DATABASE INFRASTRUCTURE (3-LAYER ARCHITECTURE)
# =============================================================================

locals {
  # Flatten databases with their schemas for easier processing
  database_schemas = var.enable_databases ? merge([
    for db_key, db_config in var.databases : {
      for schema_type in (db_config.enable_3_layer_architecture ? ["RAW", "PREPARE", "ANALYZE"] : []) :
      "${db_key}_${schema_type}" => {
        database_key = db_key
        database_config = db_config
        schema_name = schema_type
        schema_config = (
          schema_type == "RAW" ? {
            comment = "Raw data layer - unprocessed source data"
            managed = false
            transient = false
          } :
          schema_type == "PREPARE" ? {
            comment = "Prepare data layer - cleaned and transformed data"
            managed = db_config.prepare_layer_managed_access
            transient = db_config.prepare_layer_transient
          } :
          schema_type == "ANALYZE" ? {
            comment = "Analyze data layer - business-ready data for reporting and analytics"
            managed = db_config.analyze_layer_managed_access
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
        database_key = db_key
        database_config = db_config
        schema_name = schema_config.name
        schema_config = schema_config
      }
    }
  ]...) : {}

  # Combine all schemas
  all_schemas = merge(local.database_schemas, local.custom_schemas)
}

# Create databases
resource "snowflake_database" "databases" {
  for_each = var.enable_databases ? var.databases : {}

  name    = each.value.suffix != "" ? "${local.base_prefix}_${upper(each.value.suffix)}_DB" : "${local.base_prefix}_DB"
  comment = each.value.comment != "" ? each.value.comment : "Database for ${var.project_name} ${var.environment} - Managed by Terraform"
  
  # Data retention configuration
  data_retention_time_in_days = each.value.data_retention_days
  
  # Optional external volume for Iceberg tables
  external_volume = each.value.external_volume != "" ? each.value.external_volume : null
  
  # Catalog integration for Iceberg
  catalog = each.value.catalog_integration != "" ? each.value.catalog_integration : null
  
  # Console output and logging
  enable_console_output = each.value.enable_console_output
  log_level            = each.value.log_level
  trace_level          = each.value.trace_level
}

# Create schemas for databases
resource "snowflake_schema" "schemas" {
  for_each = local.all_schemas

  database = snowflake_database.databases[each.value.database_key].name
  name     = each.value.schema_name
  comment  = each.value.schema_config.comment

  # Managed access configuration
  with_managed_access = each.value.schema_config.managed ? "true" : "false"
  
  # Transient configuration
  is_transient = each.value.schema_config.transient ? "true" : "false"
  
  # Data retention (inherits from database if not specified)
  data_retention_time_in_days = lookup(each.value.schema_config, "data_retention_days", null)
  
  # Advanced schema configuration
  enable_console_output = each.value.database_config.enable_console_output
  log_level            = each.value.database_config.log_level
  trace_level          = each.value.database_config.trace_level
  
  # External volume and catalog (for Iceberg)
  external_volume = each.value.database_config.external_volume != "" ? each.value.database_config.external_volume : null
  catalog        = each.value.database_config.catalog_integration != "" ? each.value.database_config.catalog_integration : null
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
      '1.0.0' AS module_version
  SQL
  
  is_secure = false
}

# Note: Tag associations require complex syntax in provider v2.0
# Will be implemented in a future version

# =============================================================================
# WAREHOUSE INFRASTRUCTURE
# =============================================================================

resource "snowflake_warehouse" "warehouses" {
  for_each = var.enable_warehouses ? var.warehouses : {}

  name    = each.value.comment != "" ? "${local.base_prefix}_${upper(each.key)}_WH" : "${local.base_prefix}_${upper(each.key)}_WH"
  comment = each.value.comment != "" ? each.value.comment : "Warehouse ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"

  warehouse_size   = each.value.size
  min_cluster_count = each.value.min_cluster_count
  max_cluster_count = each.value.max_cluster_count
  scaling_policy   = each.value.scaling_policy
  
  auto_suspend = each.value.auto_suspend
  auto_resume  = each.value.auto_resume
  initially_suspended = each.value.initially_suspended
  
  resource_monitor = each.value.resource_monitor != "" ? each.value.resource_monitor : null
  
  enable_query_acceleration = each.value.enable_query_acceleration
  query_acceleration_max_scale_factor = each.value.query_acceleration_max_scale_factor
}

# =============================================================================
# DATA LOADING INFRASTRUCTURE
# =============================================================================

# Create stages
resource "snowflake_stage" "stages" {
  for_each = var.enable_data_loading ? var.stages : {}

  database = each.value.database
  schema   = each.value.schema
  name     = each.key
  
  comment = each.value.comment != "" ? each.value.comment : "Stage ${each.key} - Managed by Terraform"
  
  # Stage type and location
  url = each.value.url
  
  # Credentials
  credentials = each.value.credentials
  
  # File format
  file_format = each.value.file_format
  
  # Copy options
  copy_options = each.value.copy_options
  
  # Directory settings
  directory = each.value.directory
}

# Create file formats
resource "snowflake_file_format" "file_formats" {
  for_each = var.enable_data_loading ? var.file_formats : {}

  database = each.value.database
  schema   = each.value.schema
  name     = each.key
  
  format_type = each.value.format_type
  comment     = each.value.comment != "" ? each.value.comment : "File format ${each.key} - Managed by Terraform"
  
  # Format-specific options
  compression          = each.value.compression
  record_delimiter     = each.value.record_delimiter
  field_delimiter      = each.value.field_delimiter
  field_optionally_enclosed_by = each.value.field_optionally_enclosed_by
  skip_header         = each.value.skip_header
  skip_blank_lines    = each.value.skip_blank_lines
  date_format         = each.value.date_format
  time_format         = each.value.time_format
  timestamp_format    = each.value.timestamp_format
  binary_format       = each.value.binary_format
  escape              = each.value.escape
  escape_unenclosed_field = each.value.escape_unenclosed_field
  trim_space          = each.value.trim_space
  error_on_column_count_mismatch = each.value.error_on_column_count_mismatch
  replace_invalid_characters     = each.value.replace_invalid_characters
  empty_field_as_null           = each.value.empty_field_as_null
  null_if                       = each.value.null_if
  encoding                      = each.value.encoding
}

# =============================================================================
# RESOURCE MONITORS
# =============================================================================

resource "snowflake_resource_monitor" "resource_monitors" {
  for_each = var.enable_resource_monitors ? var.resource_monitors : {}

  name = "${local.base_prefix}_${upper(each.key)}_MONITOR"
  
  credit_quota                = each.value.credit_quota
  frequency                   = each.value.frequency
  start_timestamp            = each.value.start_timestamp != "" ? each.value.start_timestamp : null
  end_timestamp              = each.value.end_timestamp != "" ? each.value.end_timestamp : null
  
  # Notification thresholds
  notify_triggers    = each.value.notify_triggers
  
  # Notification settings
  notify_users = each.value.notify_users
} 