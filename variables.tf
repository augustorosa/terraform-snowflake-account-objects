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
  description = "Name of the project"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,29}$", var.project_name))
    error_message = "Project name must start with a letter, contain only letters, numbers, and underscores, and be 1-30 characters long."
  }
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
  description = "Enable network policies for security"
  type        = bool
  default     = false
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
    analyze_layer_managed_access = optional(bool, true)
    
    # Custom schemas beyond RAW, PREPARE, ANALYZE
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
    data_classification = optional(object({
      enabled              = optional(bool, false)
      auto_detect_pii      = optional(bool, false)
      confidence_threshold = optional(number, 0.8)
    }), {})
  })
  default = {
    enabled = false
  }
} 