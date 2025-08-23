# Terraform Module Outputs for Snowflake Account Objects
# Comprehensive single module with feature flags

# =============================================================================
# TAGGING OUTPUTS
# =============================================================================

output "tag_database_name" {
  description = "Name of the tag database (if created)"
  value       = var.enable_tagging && var.create_tag_schema ? snowflake_database.tag_database[0].name : null
}

output "tag_schema_name" {
  description = "Name of the tag schema (if created)"
  value       = var.enable_tagging && var.create_tag_schema ? snowflake_schema.tag_schema[0].name : null
}

output "tags_created" {
  description = "Information about created tags"
  value = var.enable_tagging && var.create_tag_schema ? {
    governance = {
      for tag_name, tag in snowflake_tag.governance_tags :
      tag_name => {
        id           = tag.id
        name         = tag.name
        database     = tag.database
        schema       = tag.schema
        allowed_values = tag.allowed_values
        comment      = tag.comment
      }
    }
    operational = {
      for tag_name, tag in snowflake_tag.operational_tags :
      tag_name => {
        id       = tag.id
        name     = tag.name
        database = tag.database
        schema   = tag.schema
        comment  = tag.comment
      }
    }
    technical = {
      for tag_name, tag in snowflake_tag.technical_tags :
      tag_name => {
        id       = tag.id
        name     = tag.name
        database = tag.database
        schema   = tag.schema
        comment  = tag.comment
      }
    }
  } : null
}

# =============================================================================
# RBAC OUTPUTS
# =============================================================================

output "functional_roles" {
  description = "Information about functional roles"
  value = var.enable_rbac && var.create_default_roles ? {
    for role_name, role in snowflake_account_role.functional_roles :
    role_name => {
      id      = role.id
      name    = role.name
      comment = role.comment
    }
  } : {}
}

output "data_access_roles" {
  description = "Information about data access roles"
  value = var.enable_rbac && var.create_default_roles ? {
    for role_name, role in snowflake_account_role.data_access_roles :
    role_name => {
      id      = role.id
      name    = role.name
      comment = role.comment
    }
  } : {}
}

output "custom_functional_roles" {
  description = "Information about custom functional roles"
  value = var.enable_rbac ? {
    for role_name, role in snowflake_account_role.custom_functional_roles :
    role_name => {
      id      = role.id
      name    = role.name
      comment = role.comment
    }
  } : {}
}

output "custom_data_access_roles" {
  description = "Information about custom data access roles"
  value = var.enable_rbac ? {
    for role_name, role in snowflake_account_role.custom_data_access_roles :
    role_name => {
      id      = role.id
      name    = role.name
      comment = role.comment
    }
  } : {}
}

output "all_roles" {
  description = "All roles created by the module"
  value = merge(
    var.enable_rbac && var.create_default_roles ? {
      for role_name, role in snowflake_account_role.functional_roles :
      role_name => {
        id      = role.id
        name    = role.name
        comment = role.comment
        type    = "functional"
      }
    } : {},
    var.enable_rbac && var.create_default_roles ? {
      for role_name, role in snowflake_account_role.data_access_roles :
      role_name => {
        id      = role.id
        name    = role.name
        comment = role.comment
        type    = "data_access"
      }
    } : {},
    var.enable_rbac ? {
      for role_name, role in snowflake_account_role.custom_functional_roles :
      role_name => {
        id      = role.id
        name    = role.name
        comment = role.comment
        type    = "custom_functional"
      }
    } : {},
    var.enable_rbac ? {
      for role_name, role in snowflake_account_role.custom_data_access_roles :
      role_name => {
        id      = role.id
        name    = role.name
        comment = role.comment
        type    = "custom_data_access"
      }
    } : {}
  )
}

output "functional_role_names" {
  description = "Names of functional roles"
  value = var.enable_rbac && var.create_default_roles ? [
    for role in snowflake_account_role.functional_roles : role.name
  ] : []
}

output "data_access_role_names" {
  description = "Names of data access roles"
  value = var.enable_rbac && var.create_default_roles ? [
    for role in snowflake_account_role.data_access_roles : role.name
  ] : []
}

output "all_role_names" {
  description = "Names of all created roles"
  value = concat(
    var.enable_rbac && var.create_default_roles ? [for role in snowflake_account_role.functional_roles : role.name] : [],
    var.enable_rbac && var.create_default_roles ? [for role in snowflake_account_role.data_access_roles : role.name] : [],
    var.enable_rbac ? [for role in snowflake_account_role.custom_functional_roles : role.name] : [],
    var.enable_rbac ? [for role in snowflake_account_role.custom_data_access_roles : role.name] : []
  )
}

# =============================================================================
# DATABASE OUTPUTS
# =============================================================================

output "databases" {
  description = "Information about created databases"
  value = var.enable_databases ? {
    for db_key, db in snowflake_database.databases :
    db_key => {
      id                   = db.id
      name                 = db.name
      fully_qualified_name = db.fully_qualified_name
      comment              = db.comment
      data_retention_days  = db.data_retention_time_in_days
    }
  } : {}
}

output "database_names" {
  description = "Names of created databases"
  value = var.enable_databases ? [
    for db in snowflake_database.databases : db.name
  ] : []
}

output "schemas" {
  description = "Information about created schemas"
  value = var.enable_databases ? {
    for schema_key, schema in snowflake_schema.schemas :
    schema_key => {
      id                   = schema.id
      name                 = schema.name
      fully_qualified_name = schema.fully_qualified_name
      comment              = schema.comment
      database             = schema.database
      managed_access       = schema.with_managed_access
      transient           = schema.is_transient
      data_retention_days = schema.data_retention_time_in_days
    }
  } : {}
}

output "schema_names" {
  description = "Names of created schemas"
  value = var.enable_databases ? [
    for schema in snowflake_schema.schemas : schema.name
  ] : []
}

output "layer_info_views" {
  description = "Information about layer info views"
  value = var.enable_databases ? {
    for view_key, view in snowflake_view.layer_info_views :
    view_key => {
      id                   = view.id
      name                 = view.name
      fully_qualified_name = view.fully_qualified_name
      comment              = view.comment
      database             = view.database
      schema               = view.schema
      statement            = view.statement
    }
  } : {}
}

# =============================================================================
# WAREHOUSE OUTPUTS
# =============================================================================

output "warehouses" {
  description = "Information about created warehouses"
  value = var.enable_warehouses ? {
    for wh_key, wh in snowflake_warehouse.warehouses :
    wh_key => {
      id               = wh.id
      name             = wh.name
      comment          = wh.comment
      size             = wh.warehouse_size
      auto_suspend     = wh.auto_suspend
      auto_resume      = wh.auto_resume
      min_cluster_count = wh.min_cluster_count
      max_cluster_count = wh.max_cluster_count
      scaling_policy   = wh.scaling_policy
    }
  } : {}
}

output "warehouse_names" {
  description = "Names of created warehouses"
  value = var.enable_warehouses ? [
    for wh in snowflake_warehouse.warehouses : wh.name
  ] : []
}

# =============================================================================
# DATA LOADING OUTPUTS
# =============================================================================

output "stages" {
  description = "Information about created stages"
  value = var.enable_data_loading ? {
    for stage_key, stage in snowflake_stage.stages :
    stage_key => {
      id                   = stage.id
      name                 = stage.name
      fully_qualified_name = stage.fully_qualified_name
      comment              = stage.comment
      database             = stage.database
      schema               = stage.schema
      url                  = stage.url
    }
  } : {}
}

output "file_formats" {
  description = "Information about created file formats"
  value = var.enable_data_loading ? {
    for format_key, format in snowflake_file_format.file_formats :
    format_key => {
      id                   = format.id
      name                 = format.name
      fully_qualified_name = format.fully_qualified_name
      comment              = format.comment
      database             = format.database
      schema               = format.schema
      format_type          = format.format_type
    }
  } : {}
}

# =============================================================================
# RESOURCE MONITOR OUTPUTS
# =============================================================================

output "resource_monitors" {
  description = "Information about created resource monitors"
  value = var.enable_resource_monitors ? {
    for monitor_key, monitor in snowflake_resource_monitor.resource_monitors :
    monitor_key => {
      id              = monitor.id
      name            = monitor.name
      credit_quota    = monitor.credit_quota
      frequency       = monitor.frequency
      notify_triggers = monitor.notify_triggers
    }
  } : {}
}

# =============================================================================
# CONFIGURATION SUMMARY
# =============================================================================

output "configuration_summary" {
  description = "Summary of module configuration and created resources"
  value = {
    project_name = var.project_name
    environment  = var.environment
    
    features_enabled = {
      rbac             = var.enable_rbac
      tagging          = var.enable_tagging
      databases        = var.enable_databases
      warehouses       = var.enable_warehouses
      data_loading     = var.enable_data_loading
      resource_monitors = var.enable_resource_monitors
      network_policies = var.enable_network_policies
    }
    
    resources_created = {
      tag_database        = var.enable_tagging && var.create_tag_schema ? 1 : 0
      governance_tags     = var.enable_tagging && var.create_tag_schema ? length(var.tag_categories.governance.tags) : 0
      operational_tags    = var.enable_tagging && var.create_tag_schema ? length(var.tag_categories.operational.tags) : 0
      technical_tags      = var.enable_tagging && var.create_tag_schema ? length(var.tag_categories.technical.tags) : 0
      functional_roles    = var.enable_rbac && var.create_default_roles ? 3 : 0
      data_access_roles   = var.enable_rbac && var.create_default_roles ? 3 : 0
      custom_functional_roles = var.enable_rbac ? length(var.custom_functional_roles) : 0
      custom_data_access_roles = var.enable_rbac ? length(var.custom_data_access_roles) : 0
      databases          = var.enable_databases ? length(var.databases) : 0
      schemas            = var.enable_databases ? length(local.all_schemas) : 0
      layer_info_views   = var.enable_databases ? length(snowflake_view.layer_info_views) : 0
      warehouses         = var.enable_warehouses ? length(var.warehouses) : 0
      stages             = var.enable_data_loading ? length(var.stages) : 0
      file_formats       = var.enable_data_loading ? length(var.file_formats) : 0
      resource_monitors  = var.enable_resource_monitors ? length(var.resource_monitors) : 0
    }
    
    naming_prefix = local.base_prefix
    tag_database_name = var.enable_tagging ? local.tag_database_name : null
  }
}

# =============================================================================
# SQL COMMANDS FOR MANUAL OPERATIONS
# =============================================================================

output "sql_commands" {
  description = "Useful SQL commands for managing the Snowflake account objects"
  value = {
    # Role management commands
    rbac_commands = var.enable_rbac ? {
      show_all_roles = "SHOW ROLES LIKE '${local.base_prefix}%';"
      use_reader_role = var.create_default_roles ? "USE ROLE ${local.base_prefix}_READER_ROLE;" : null
      use_writer_role = var.create_default_roles ? "USE ROLE ${local.base_prefix}_WRITER_ROLE;" : null
      use_admin_role = var.create_default_roles ? "USE ROLE ${local.base_prefix}_ADMIN_ROLE;" : null
      show_role_grants = var.create_default_roles ? "SHOW GRANTS TO ROLE ${local.base_prefix}_ADMIN_ROLE;" : null
    } : null
    
    # Database commands
    database_commands = var.enable_databases ? {
      show_databases = "SHOW DATABASES LIKE '${local.base_prefix}%';"
      show_schemas = length(var.databases) > 0 ? "SHOW SCHEMAS IN DATABASE ${values(snowflake_database.databases)[0].name};" : null
      use_database = length(var.databases) > 0 ? "USE DATABASE ${values(snowflake_database.databases)[0].name};" : null
    } : null
    
    # Warehouse commands
    warehouse_commands = var.enable_warehouses ? {
      show_warehouses = "SHOW WAREHOUSES LIKE '${local.base_prefix}%';"
      use_warehouse = length(var.warehouses) > 0 ? "USE WAREHOUSE ${values(snowflake_warehouse.warehouses)[0].name};" : null
    } : null
    
    # Data loading commands
    data_loading_commands = var.enable_data_loading ? {
      show_stages = length(var.stages) > 0 ? "SHOW STAGES;" : null
      show_file_formats = length(var.file_formats) > 0 ? "SHOW FILE FORMATS;" : null
    } : null
    
    # Resource monitoring commands
    resource_monitor_commands = var.enable_resource_monitors ? {
      show_resource_monitors = "SHOW RESOURCE MONITORS LIKE '${local.base_prefix}%';"
    } : null
    
    # Tagging commands
    tagging_commands = var.enable_tagging && var.create_tag_schema ? {
      show_tags = "SHOW TAGS IN SCHEMA ${snowflake_database.tag_database[0].name}.TAG_DEFINITIONS;"
      use_tag_database = "USE DATABASE ${snowflake_database.tag_database[0].name};"
    } : null
  }
}

# =============================================================================
# MODULE METADATA
# =============================================================================

output "module_metadata" {
  description = "Metadata about the module deployment"
  value = {
    module_version = "1.0.0"
    terraform_version = "~> 1.5.7"
    snowflake_provider_version = "~> 2.0"
    deployment_timestamp = timestamp()
    
    feature_flags = {
      rbac             = var.enable_rbac
      tagging          = var.enable_tagging
      databases        = var.enable_databases
      warehouses       = var.enable_warehouses
      data_loading     = var.enable_data_loading
      resource_monitors = var.enable_resource_monitors
      network_policies = var.enable_network_policies
    }
    
    cortex_ai_enabled = var.cortex_ai_features.enabled
  }
} 