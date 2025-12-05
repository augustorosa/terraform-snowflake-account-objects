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
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
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

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "owner_email" {
  description = "Email of the resource owner"
  type        = string
  default     = "data-team@company.com"
}

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
