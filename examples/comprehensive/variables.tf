# =============================================================================
# VARIABLES - Comprehensive Example
# =============================================================================

# -----------------------------------------------------------------------------
# Snowflake Connection Variables
# -----------------------------------------------------------------------------

variable "organization_name" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
  sensitive   = true
}

variable "snowflake_username" {
  description = "Snowflake username"
  type        = string
  sensitive   = true
}

variable "snowflake_password" {
  description = "Snowflake password or PAT token"
  type        = string
  sensitive   = true
}

variable "preview_features_enabled" {
  description = "List of preview features to enable"
  type        = list(string)
  default     = []
}

variable "snowflake_warehouse" {
  description = "Snowflake warehouse to use for provider connection (optional, defaults to COMPUTE_WH if exists)"
  type        = string
  default     = null
  sensitive   = false
}

variable "snowflake_role" {
  description = "Snowflake role to use for provider connection (defaults to ACCOUNTADMIN)"
  type        = string
  default     = "ACCOUNTADMIN"
  sensitive   = false
}

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.project_name))
    error_message = "Project name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}

# -----------------------------------------------------------------------------
# Organization Details
# -----------------------------------------------------------------------------

variable "team_name" {
  description = "Name of the team owning these resources"
  type        = string
  default     = "data-platform"
}

# Note: cost_center and owner_email removed - these tags are defined in tag_categories
# but not automatically applied by the module. To use them, add tag associations manually
# or extend the module to support them.

# -----------------------------------------------------------------------------
# Resource Configuration
# -----------------------------------------------------------------------------

variable "data_retention_days" {
  description = "Data retention period in days for databases"
  type        = number
  default     = 7

  validation {
    condition     = var.data_retention_days >= 0 && var.data_retention_days <= 90
    error_message = "Data retention must be between 0 and 90 days."
  }
}

variable "monthly_credit_quota" {
  description = "Monthly credit quota for resource monitor"
  type        = number
  default     = 100

  validation {
    condition     = var.monthly_credit_quota > 0
    error_message = "Credit quota must be greater than 0."
  }
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "enable_network_policies" {
  description = "Enable network policies and rules"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for network policy"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# -----------------------------------------------------------------------------
# Service Users & Authentication
# -----------------------------------------------------------------------------

variable "service_users" {
  description = "Service users to create with optional RSA key-pair authentication"
  type = map(object({
    comment              = optional(string, "Service user managed by Terraform")
    default_role         = optional(string, "PUBLIC")
    default_warehouse    = optional(string)
    disabled             = optional(bool, false)
    display_name         = optional(string)
    email                = optional(string)
    login_name           = optional(string)
    rsa_public_key       = optional(string, null) # Base64 encoded public key
    rsa_public_key_2     = optional(string, null) # For key rotation
    days_to_expiry       = optional(number, null) # Account expiry
  }))
  default = {}
}

variable "pat_tokens" {
  description = "Personal Access Tokens to create for service users"
  type = map(object({
    user_name                                 = string
    comment                                   = optional(string, "PAT token managed by Terraform")
    days_to_expiry                            = optional(number, 90)
    disabled                                  = optional(bool, false)
    role_restriction                          = optional(list(string), [])
    mins_to_bypass_network_policy_requirement = optional(number, null)
    expire_rotated_token_after_hours          = optional(number, 24)
  }))
  default = {}
}
