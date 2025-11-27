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

variable "enable_resource_monitors" {
  description = "Enable resource monitors for cost control"
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

variable "enable_cortex_ai" {
  description = "Enable Cortex AI features (requires appropriate Snowflake edition)"
  type        = bool
  default     = false
}

# =============================================================================
# SERVICE USERS CONFIGURATION
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
    login_name            = optional(string)
    rsa_public_key        = optional(string, null)  # Base64 encoded public key
    rsa_public_key_2      = optional(string, null)  # For key rotation
    days_to_expiry        = optional(number, null)  # Account expiry
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