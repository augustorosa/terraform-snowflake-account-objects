# Terraform Module Outputs for Snowflake Account Objects
# Comprehensive single module with feature flags

# =============================================================================
# CENTRAL SETTINGS DATABASE OUTPUTS
# =============================================================================

output "central_settings_database" {
  description = "Central settings database details"
  value = var.enable_central_settings_db ? {
    name    = snowflake_database.central_settings[0].name
    comment = snowflake_database.central_settings[0].comment
    schemas = {
      network    = var.enable_network_policies ? snowflake_schema.network_schema[0].name : null
      governance = snowflake_schema.governance_schema[0].name
      security   = snowflake_schema.security_schema[0].name
      audit      = snowflake_schema.audit_schema[0].name
      tags       = var.enable_tagging && var.use_central_db_for_tags ? snowflake_schema.tags_schema[0].name : null
    }
  } : null
}

# =============================================================================
# TAGGING OUTPUTS
# =============================================================================

output "tag_database_name" {
  description = "Name of the tag database (if created)"
  value       = var.enable_tagging && var.create_tag_schema ? local.tag_database : null
}

output "tag_schema_name" {
  description = "Name of the tag schema (if created)"
  value       = var.enable_tagging && var.create_tag_schema ? local.tag_schema : null
}

output "tags_created" {
  description = "Information about created tags"
  value = var.enable_tagging && var.create_tag_schema ? {
    governance = {
      for tag_name, tag in snowflake_tag.governance_tags :
      tag_name => {
        id             = tag.id
        name           = tag.name
        fully_qualified_name = tag.fully_qualified_name
        database       = tag.database
        schema         = tag.schema
        allowed_values = tag.allowed_values
        comment        = tag.comment
      }
    }
    operational = {
      for tag_name, tag in snowflake_tag.operational_tags :
      tag_name => {
        id             = tag.id
        name           = tag.name
        fully_qualified_name = tag.fully_qualified_name
        database       = tag.database
        schema         = tag.schema
        comment        = tag.comment
      }
    }
    technical = {
      for tag_name, tag in snowflake_tag.technical_tags :
      tag_name => {
        id             = tag.id
        name           = tag.name
        fully_qualified_name = tag.fully_qualified_name
        database       = tag.database
        schema         = tag.schema
        comment  = tag.comment
      }
    }
  } : null
}

output "tag_associations_summary" {
  description = "Summary of tag associations applied to resources"
  value = var.enable_tagging && var.auto_apply_tags && var.create_tag_schema ? {
    databases_tagged = var.enable_databases ? length(var.databases) : 0
    warehouses_tagged = var.enable_warehouses ? length(var.warehouses) : 0
    schemas_tagged = var.enable_databases ? length(local.all_schemas) : 0
    roles_tagged = var.enable_rbac && var.create_default_roles ? 3 : 0
    service_users_tagged = var.enable_key_pair_auth ? length(var.service_users) : 0
    central_db_tagged = var.enable_central_settings_db ? 1 : 0
    tags_applied = [
      "environment",
      "project", 
      "terraform_managed",
      "module_version",
      "data_classification"
    ]
  } : {
    message = "Auto-tagging is disabled. Set auto_apply_tags = true to enable."
  }
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
# AUTOMATIC CLASSIFICATION OUTPUTS
# =============================================================================

output "classification_enabled" {
  description = "Whether automatic classification is enabled"
  value       = local.classification_enabled
}

output "classification_profile_name" {
  description = "Name of the classification profile (if enabled)"
  value       = local.classification_profile_name
}

output "classification_setup_commands" {
  description = "SQL commands for setting up automatic classification (Enterprise Edition required)"
  value = local.classification_enabled ? [
    "-- Step 1: Create Classification Profile",
    "CREATE OR REPLACE SNOWFLAKE.DATA_PRIVACY.CLASSIFICATION_PROFILE ${local.classification_profile_name}({'minimum_object_age_for_classification_days': ${var.classification_config.minimum_object_age_days}, 'maximum_classification_validity_days': ${var.classification_config.maximum_validity_days}, 'auto_tag': ${var.classification_config.auto_tag ? "true" : "false"}});",
    "",
    "-- Step 2: Assign Profile to Schema (replace with your database and schema)",
    "ALTER SCHEMA your_database.your_schema SET CLASSIFICATION_PROFILE = '${local.classification_profile_name}';",
    "",
    "-- Step 3: Test Classification on a Table (optional)",
    "CALL SYSTEM$$CLASSIFY('your_database.your_schema.your_table', '${local.classification_profile_name}');",
    "",
    "-- Step 4: View Results",
    "SELECT SYSTEM$$GET_CLASSIFICATION_RESULT('your_database.your_schema.your_table');",
    "",
    "-- More info: https://docs.snowflake.com/en/user-guide/classify-auto"
  ] : ["Automatic classification is not enabled. Set enable_auto_classification = true to enable."]
}

output "classification_instructions" {
  description = "Instructions for setting up automatic classification (Enterprise Edition required)"
  value       = local.classification_enabled ? "Automatic classification is enabled. Run the classification SQL commands provided in classification_sql_commands output." : "Automatic classification is not enabled. Set enable_auto_classification = true to enable."
}

# =============================================================================
# AUTHENTICATION POLICIES OUTPUTS
# =============================================================================

output "authentication_policies" {
  description = "Created authentication policies with their configurations"
  value = {
    for name, policy in snowflake_authentication_policy.auth_policies : name => {
      id                        = policy.id
      name                      = policy.name
      authentication_methods    = policy.authentication_methods
      mfa_authentication_methods = policy.mfa_authentication_methods
      mfa_enrollment           = policy.mfa_enrollment
      client_types             = policy.client_types
    }
  }
}

# =============================================================================
# EXTERNAL OAUTH INTEGRATIONS OUTPUTS
# =============================================================================

output "external_oauth_integrations" {
  description = "Created external OAuth integrations for workload identity federation"
  value = {
    for name, integration in snowflake_external_oauth_integration.oauth_integrations : name => {
      id                  = integration.id
      name                = integration.name
      type                = integration.type
      enabled             = integration.enabled
      external_oauth_type = integration.external_oauth_type
      external_oauth_issuer = integration.external_oauth_issuer
    }
  }
  sensitive = false
}

output "workload_identity_setup_guide" {
  description = "Guide for setting up workload identity federation"
  value = var.enable_external_oauth ? "External OAuth integrations enabled. Configure your identity provider to use the created integrations for secure, credential-less authentication." : "External OAuth integrations are disabled. Enable with enable_external_oauth = true"
}

# =============================================================================
# KEY-PAIR AUTHENTICATION OUTPUTS
# =============================================================================

output "service_users" {
  description = "Created service users with their details"
  value = {
    for name, user in snowflake_service_user.service_users : name => {
      id               = user.id
      name             = user.name
      login_name       = user.login_name
      display_name     = user.display_name
      default_role     = user.default_role
      default_warehouse = user.default_warehouse
      disabled         = user.disabled
      has_rsa_public_key   = user.rsa_public_key != null
      has_rsa_public_key_2 = user.rsa_public_key_2 != null
      days_to_expiry   = user.days_to_expiry
    }
  }
}

output "key_generation_function" {
  description = "Name of the key generation function for creating RSA key pairs"
  value       = var.enable_key_pair_auth ? "${local.base_prefix}_GENERATE_KEY_PAIR_UDTF" : null
}

output "key_generation_sql" {
  description = "SQL command to generate RSA key pairs using the Snowpark UDTF"
  value = var.enable_key_pair_auth ? "SELECT encrypted_pem_private_key, pem_private_key, pem_public_key, passphrase, private_key, public_key FROM TABLE(${local.base_prefix}_GENERATE_KEY_PAIR_UDTF('YourPassphrase'));" : null
}

# =============================================================================
# PAT TOKEN OUTPUTS
# =============================================================================

output "pat_tokens" {
  description = "Created PAT tokens with their metadata"
  value = {
    for name, token in snowflake_user_programmatic_access_token.pat_tokens : name => {
      id                    = token.id
      name                  = token.name
      user                  = token.user
      days_to_expiry        = token.days_to_expiry
      disabled              = token.disabled
      role_restriction      = token.role_restriction
    }
  }
  sensitive = true  # Marked sensitive to prevent exposure in logs
}

output "pat_token_values" {
  description = "Actual PAT token values (SENSITIVE - handle with care)"
  value = {
    for name, token in snowflake_user_programmatic_access_token.pat_tokens : name => {
      token = token.token
    }
  }
  sensitive = true
}

output "authentication_setup_guide" {
  description = "Complete guide for setting up authentication with this module"
  value = var.enable_key_pair_auth || var.enable_pat_tokens ? "Authentication features enabled. See key_generation_sql and pat_tokens outputs for details." : "Authentication features are disabled. Enable with enable_key_pair_auth = true or enable_pat_tokens = true"
}

# =============================================================================
# NETWORK POLICY OUTPUTS
# =============================================================================

output "network_rules" {
  description = "Created network rules for IP-based access control"
  value = {
    for name, rule in snowflake_network_rule.network_rules : name => {
      id         = rule.id
      name       = rule.name
      type       = rule.type
      value_list = rule.value_list
      mode       = rule.mode
    }
  }
}

output "network_policies" {
  description = "Created network policies with their configurations"  
  value = {
    for name, policy in snowflake_network_policy.network_policies : name => {
      id                        = policy.id
      name                      = policy.name
      allowed_ip_list          = policy.allowed_ip_list
      blocked_ip_list          = policy.blocked_ip_list
      allowed_network_rule_list = policy.allowed_network_rule_list
      blocked_network_rule_list = policy.blocked_network_rule_list
    }
  }
}

output "default_network_policy" {
  description = "Default network policy details (if created)"
  value = var.enable_network_policies && var.default_network_policy.enabled ? {
    id              = snowflake_network_policy.default_policy[0].id
    name            = snowflake_network_policy.default_policy[0].name
    allowed_ip_list = snowflake_network_policy.default_policy[0].allowed_ip_list
    blocked_ip_list = snowflake_network_policy.default_policy[0].blocked_ip_list
  } : null
}

output "network_policy_setup_guide" {
  description = "Guide for setting up network policies for PAT tokens"
  value = var.enable_network_policies ? "Network policies enabled. PAT tokens can now be created with network policy restrictions. See network_policies output for details." : "Network policies are disabled. Enable with enable_network_policies = true"
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