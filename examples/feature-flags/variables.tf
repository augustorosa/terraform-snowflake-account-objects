# Feature Flags Example Variables

# =============================================================================
# SNOWFLAKE CONNECTION VARIABLES
# =============================================================================

variable "organization_name" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account" {
  description = "Snowflake account name"
  type        = string
}

variable "snowflake_username" {
  description = "Snowflake username"
  type        = string
  sensitive   = true
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
}

variable "preview_features_enabled" {
  description = "List of preview features to enable"
  type        = list(string)
  default     = ["snowflake_table_resource"]
}

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "analytics"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,29}$", var.project_name))
    error_message = "Project name must start with a letter, contain only letters, numbers, and underscores, and be 1-30 characters long."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], lower(var.environment))
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# =============================================================================
# S3 CONFIGURATION (FOR DATA LOADING EXAMPLES)
# =============================================================================

variable "s3_data_lake_url" {
  description = "S3 URL for data lake stage (example: s3://your-bucket/data-lake/)"
  type        = string
  default     = "@~/data_lake/"  # Internal stage fallback
}

variable "s3_streaming_url" {
  description = "S3 URL for streaming data stage (example: s3://your-bucket/streaming/)"
  type        = string
  default     = "@~/streaming/"  # Internal stage fallback
}

variable "s3_credentials" {
  description = "S3 credentials for external stages (example: AWS_KEY_ID='key' AWS_SECRET_KEY='secret')"
  type        = string
  default     = ""  # Empty for internal stages
  sensitive   = true
}

# =============================================================================
# NOTIFICATION CONFIGURATION
# =============================================================================

variable "admin_email_list" {
  description = "List of admin email addresses for notifications"
  type        = list(string)
  default     = ["admin@example.com"]
}

variable "etl_team_emails" {
  description = "List of ETL team email addresses for notifications"
  type        = list(string)
  default     = ["etl-team@example.com"]
}

variable "dev_team_emails" {
  description = "List of development team email addresses for notifications"
  type        = list(string)
  default     = ["dev-team@example.com"]
}

# =============================================================================
# FEATURE TOGGLES
# =============================================================================

variable "enable_cortex_ai" {
  description = "Enable Cortex AI features (requires appropriate Snowflake edition)"
  type        = bool
  default     = false
}

variable "deploy_full_stack" {
  description = "Deploy the full-featured stack (all features enabled)"
  type        = bool
  default     = true
}

variable "deploy_minimal_stack" {
  description = "Deploy the minimal stack (RBAC + tagging only)"
  type        = bool
  default     = false
}

variable "deploy_database_only" {
  description = "Deploy the database-only stack (RBAC + tagging + databases)"
  type        = bool
  default     = false
} 