# Terraform Module Variables for Snowflake Account Objects
# Comprehensive single module with feature flags

# =============================================================================
# SNOWFLAKE CONNECTION CONFIGURATION
# =============================================================================
# Provider configuration is handled at the calling level (examples/feature-flags/main.tf)
# This allows for count, for_each, and depends_on usage with the module

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Name of the project (also used as central database name)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,29}$", var.project_name))
    error_message = "Project name must start with a letter, contain only letters, numbers, and underscores, and be 1-30 characters long."
  }
}

variable "module_version" {
  description = "Version of the module (used for tagging resources)"
  type        = string
  default     = "0.6.0"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], lower(var.environment))
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# =============================================================================
# FEATURE FLAGS - ENABLE/DISABLE MODULE COMPONENTS
# =============================================================================

variable "enable_rbac" {
  description = "Enable RBAC (roles and grants) creation"
  type        = bool
  default     = true
}

variable "enable_tagging" {
  description = "Enable tagging infrastructure (tag database and schema)"
  type        = bool
  default     = true
}

variable "enable_databases" {
  description = "Enable database creation with 3-layer architecture"
  type        = bool
  default     = true
}

variable "enable_warehouses" {
  description = "Enable warehouse creation and management"
  type        = bool
  default     = false
}

variable "enable_data_loading" {
  description = "Enable data loading infrastructure (stages, file formats, pipes)"
  type        = bool
  default     = false
}

variable "enable_resource_monitors" {
  description = "Enable resource monitors for cost control"
  type        = bool
  default     = false
}

variable "enable_network_policies" {
  description = "Enable network policies for IP-based security control"
  type        = bool
  default     = false
}

variable "enable_auto_classification" {
  description = "Enable automatic sensitive data classification (requires Enterprise Edition)"
  type        = bool
  default     = false
}

variable "enable_key_pair_auth" {
  description = "Enable RSA key-pair authentication for service users"
  type        = bool
  default     = false
}

variable "enable_pat_tokens" {
  description = "Enable Personal Access Token (PAT) creation for service users"
  type        = bool
  default     = false
}

variable "enable_authentication_policies" {
  description = "Enable authentication policies for enhanced security controls"
  type        = bool
  default     = false
}

variable "enable_external_oauth" {
  description = "Enable external OAuth integrations for workload identity federation"
  type        = bool
  default     = false
}

# =============================================================================
# CENTRAL SETTINGS DATABASE
# =============================================================================

variable "enable_central_settings_db" {
  description = "Enable central settings database for network rules, governance, and security configurations"
  type        = bool
  default     = true
}

variable "central_settings_data_retention_days" {
  description = "Data retention days for central settings database"
  type        = number
  default     = 90
}

variable "use_central_db_for_tags" {
  description = "Use central settings database for tag definitions instead of legacy tag database"
  type        = bool
  default     = false  # Set to true to migrate tags to central database
}

# =============================================================================
# RBAC CONFIGURATION
# =============================================================================

variable "create_default_roles" {
  description = "Create default functional and data access roles"
  type        = bool
  default     = true
}

variable "custom_functional_roles" {
  description = "Additional functional roles to create beyond READER, WRITER, ADMIN"
  type = map(object({
    comment = optional(string, "")
    inherit_from = optional(string, "")
  }))
  default = {}
}

variable "custom_data_access_roles" {
  description = "Additional data access roles to create"
  type = map(object({
    comment = optional(string, "")
  }))
  default = {}
}

# =============================================================================
# TAGGING CONFIGURATION
# =============================================================================

variable "create_tag_schema" {
  description = "Create tag database and schema for resource tagging"
  type        = bool
  default     = true
}

variable "auto_apply_tags" {
  description = "Automatically apply governance and technical tags to all resources"
  type        = bool
  default     = true
}

variable "tag_database_suffix" {
  description = "Suffix for the tag database name"
  type        = string
  default     = "TAGS"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}

variable "tag_categories" {
  description = "Tag categories and their allowed values"
  type = object({
    governance = object({
      required = bool
      tags     = list(string)
    })
    operational = object({
      required = bool
      tags     = list(string)
    })
    technical = object({
      required = bool
      tags     = list(string)
    })
  })
  default = {
    governance = {
      required = true
      tags     = ["environment", "project", "owner", "cost_center", "data_classification"]
    }
    operational = {
      required = false
      tags     = ["created_by", "created_date", "last_modified_by", "last_modified_date"]
    }
    technical = {
      required = false
      tags     = ["version", "terraform_managed", "module_version"]
    }
  }
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "databases" {
  description = "Configuration for databases to create"
  type = map(object({
    comment                      = optional(string, "")
    suffix                      = optional(string, "")
    data_retention_days         = optional(number, 1)
    
    # 3-Layer Architecture
    enable_3_layer_architecture = optional(bool, true)
    prepare_layer_managed_access = optional(bool, false)
    prepare_layer_transient     = optional(bool, false)
    analysis_layer_managed_access = optional(bool, true)
    
    # Custom schemas beyond RAW, PREPARE, ANALYSIS
    custom_schemas = optional(map(object({
      name                   = string
      comment               = optional(string, "")
      managed               = optional(bool, false)
      transient             = optional(bool, false)
      data_retention_days   = optional(number)
      pipe_execution_paused = optional(bool, false)
    })), {})
    
    # Features
    create_layer_info_views = optional(bool, true)
    enable_data_loading     = optional(bool, false)
    
    # Advanced configuration
    enable_console_output = optional(bool, false)
    log_level            = optional(string, "OFF")
    trace_level          = optional(string, "OFF")
    external_volume      = optional(string, "")
    catalog_integration  = optional(string, "")
  }))
  default = {
    main = {
      comment = "Main database with 3-layer architecture"
      suffix  = ""
    }
  }
}

# =============================================================================
# WAREHOUSE CONFIGURATION
# =============================================================================

variable "warehouses" {
  description = "Configuration for warehouses to create"
  type = map(object({
    comment                         = optional(string, "")
    size                           = optional(string, "X-SMALL")
    min_cluster_count              = optional(number, 1)
    max_cluster_count              = optional(number, 1)
    scaling_policy                 = optional(string, "STANDARD")
    auto_suspend                   = optional(number, 60)
    auto_resume                    = optional(bool, true)
    initially_suspended            = optional(bool, true)
    resource_monitor               = optional(string, "")
    enable_query_acceleration      = optional(bool, false)
    query_acceleration_max_scale_factor = optional(number, 8)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.warehouses : contains([
        "X-SMALL", "XSMALL", "SMALL", "MEDIUM", "LARGE", 
        "X-LARGE", "XLARGE", "2X-LARGE", "2XLARGE", 
        "3X-LARGE", "3XLARGE", "4X-LARGE", "4XLARGE",
        "5X-LARGE", "5XLARGE", "6X-LARGE", "6XLARGE"
      ], upper(v.size))
    ])
    error_message = "Warehouse size must be a valid Snowflake warehouse size (X-SMALL, SMALL, MEDIUM, LARGE, X-LARGE, 2X-LARGE, etc.)."
  }

  validation {
    condition = alltrue([
      for k, v in var.warehouses : contains(["STANDARD", "ECONOMY"], upper(v.scaling_policy))
    ])
    error_message = "Scaling policy must be either STANDARD or ECONOMY."
  }
}

# =============================================================================
# DATA LOADING CONFIGURATION
# =============================================================================

variable "stages" {
  description = "Configuration for stages to create"
  type = map(object({
    database     = string
    schema       = string
    comment      = optional(string, "")
    url          = optional(string)
    credentials  = optional(string)
    file_format  = optional(string, "TYPE = CSV")
    copy_options = optional(string)
    directory    = optional(string)
  }))
  default = {}
}

variable "file_formats" {
  description = "Configuration for file formats to create"
  type = map(object({
    database                       = string
    schema                        = string
    format_type                   = string
    comment                       = optional(string)
    compression                   = optional(string, "AUTO")
    record_delimiter              = optional(string)
    field_delimiter               = optional(string)
    field_optionally_enclosed_by  = optional(string)
    skip_header                   = optional(number)
    skip_blank_lines              = optional(bool)
    date_format                   = optional(string)
    time_format                   = optional(string)
    timestamp_format              = optional(string)
    binary_format                 = optional(string)
    escape                        = optional(string)
    escape_unenclosed_field       = optional(string)
    trim_space                    = optional(bool)
    error_on_column_count_mismatch = optional(bool)
    replace_invalid_characters     = optional(bool)
    empty_field_as_null           = optional(bool)
    null_if                       = optional(list(string))
    encoding                      = optional(string)
  }))
  default = {}
}

# =============================================================================
# RESOURCE MONITOR CONFIGURATION
# =============================================================================

variable "resource_monitors" {
  description = "Configuration for resource monitors to create"
  type = map(object({
    comment                = optional(string, "")
    credit_quota          = number
    frequency             = optional(string, "MONTHLY")
    start_timestamp       = optional(string, "")
    end_timestamp         = optional(string, "")
    notify_triggers       = optional(list(number), [80])
    suspend_triggers      = optional(list(number), [100])
    notify_users         = optional(list(string), [])
    set_for_account      = optional(bool, false)
    warehouses           = optional(list(string), [])
  }))
  default = {}
}

# =============================================================================
# CORTEX AI FEATURES
# =============================================================================

# =============================================================================
# AUTOMATIC CLASSIFICATION CONFIGURATION
# =============================================================================

variable "classification_config" {
  description = "Configuration for automatic sensitive data classification"
  type = object({
    minimum_object_age_days     = optional(number, 0)
    maximum_validity_days       = optional(number, 30)
    auto_tag                   = optional(bool, true)
    enable_system_tags         = optional(bool, true)
    custom_tag_mappings = optional(list(object({
      tag_name            = string
      tag_value           = string
      semantic_categories = list(string)
    })), [])
  })
  default = {
    minimum_object_age_days = 0
    maximum_validity_days   = 30
    auto_tag               = true
    enable_system_tags     = true
    custom_tag_mappings    = []
  }
}

variable "cortex_ai_features" {
  description = "Cortex AI features configuration (disabled by default)"
  type = object({
    enabled = optional(bool, false)
    column_descriptions = optional(object({
      enabled       = optional(bool, false)
      auto_generate = optional(bool, false)
      languages     = optional(list(string), ["en"])
    }), {})
    table_documentation = optional(object({
      enabled                = optional(bool, false)
      auto_summarize         = optional(bool, false)
      include_usage_patterns = optional(bool, false)
    }), {})
  })
  default = {
    enabled = false
  }
} 

# =============================================================================
# KEY-PAIR AUTHENTICATION CONFIGURATION
# =============================================================================

variable "service_users" {
  description = "Service users to create with optional RSA key-pair authentication"
  type = map(object({
    comment                = optional(string, "Service user managed by Terraform")
    default_role          = optional(string, "PUBLIC")
    default_warehouse     = optional(string)
    disabled              = optional(bool, false)
    display_name          = optional(string)
    email                 = optional(string)
    first_name            = optional(string)
    last_name             = optional(string)
    login_name            = optional(string)
    must_change_password  = optional(bool, false)
    rsa_public_key        = optional(string, null)  # Base64 encoded public key
    rsa_public_key_2      = optional(string, null)  # For key rotation
    days_to_expiry        = optional(number, null)  # Account expiry
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for user_name, user in var.service_users : 
      can(regex("^[A-Z0-9_]+$", user_name))
    ])
    error_message = "Service user names must contain only uppercase letters, numbers, and underscores."
  }
}

# =============================================================================
# AUTHENTICATION POLICIES CONFIGURATION
# =============================================================================

variable "authentication_policies" {
  description = "Authentication policies for enhanced security controls"
  type = map(object({
    comment                    = optional(string, "Authentication policy managed by Terraform")
    authentication_methods     = optional(list(string), ["PASSWORD"])
    mfa_authentication_methods = optional(list(string), ["PASSWORD"])
    mfa_enrollment            = optional(string, "OPTIONAL")  # REQUIRED, OPTIONAL
    client_types              = optional(list(string), ["SNOWFLAKE_UI", "DRIVERS", "SNOWSQL"])
  }))
  default = {}
}

# =============================================================================
# EXTERNAL OAUTH CONFIGURATION
# =============================================================================

variable "external_oauth_integrations" {
  description = "External OAuth integrations for workload identity federation"
  type = map(object({
    comment                     = optional(string, "External OAuth integration managed by Terraform")
    type                       = string  # EXTERNAL_OAUTH
    enabled                    = optional(bool, true)
    external_oauth_type        = string  # AZURE, OKTA, PING_IDENTITY, CUSTOM
    external_oauth_issuer      = string
    external_oauth_jws_keys_url = optional(string)
    external_oauth_audience_list = optional(list(string))
    external_oauth_token_user_mapping_claim = optional(string, "sub")
    external_oauth_snowflake_user_mapping_attribute = optional(string, "LOGIN_NAME")
    external_oauth_scope_delimiter = optional(string, " ")
  }))
  default = {}
}

# =============================================================================
# PAT TOKEN CONFIGURATION
# =============================================================================

variable "pat_tokens" {
  description = "Personal Access Tokens to create for service users"
  type = map(object({
    user_name                                = string
    comment                                 = optional(string, "PAT token managed by Terraform")
    days_to_expiry                         = optional(number, 90)
    disabled                               = optional(bool, false)
    role_restriction                       = optional(list(string), [])
    mins_to_bypass_network_policy_requirement = optional(number, null)
    expire_rotated_token_after_hours       = optional(number, 24)
  }))
  default = {}
}

# =============================================================================
# NETWORK POLICY CONFIGURATION
# =============================================================================

variable "network_policies" {
  description = "Network policies to create for IP-based access control"
  type = map(object({
    comment           = optional(string, "Network policy managed by Terraform")
    allowed_ip_list   = optional(list(string), [])
    blocked_ip_list   = optional(list(string), [])
    allowed_network_rule_list = optional(list(string), [])
    blocked_network_rule_list = optional(list(string), [])
  }))
  default = {}
}

variable "network_rules" {
  description = "Network rules to define IP ranges and patterns"
  type = map(object({
    comment    = optional(string, "Network rule managed by Terraform")
    type       = string # IPV4, IPV6, FQDN
    value_list = list(string)
    mode       = optional(string, "INGRESS") # INGRESS, EGRESS
  }))
  default = {}
}

variable "default_network_policy" {
  description = "Default network policy configuration for basic IP restrictions"
  type = object({
    enabled             = optional(bool, false)
    name               = optional(string, "DEFAULT_ACCESS_POLICY")
    comment            = optional(string, "Default network policy - allows all by default")
    allowed_ip_list    = optional(list(string), ["0.0.0.0/0"])
    blocked_ip_list    = optional(list(string), [])
  })
  default = {
    enabled = false
  }
} 