# Snowflake Connection Variables
# These are configured via environment variables:
# SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_REGION

variable "snowflake_account" {
  description = "Snowflake account identifier (from environment variable SNOWFLAKE_ACCOUNT)"
  type        = string
  sensitive   = true
}

variable "snowflake_username" {
  description = "Snowflake username (from environment variable SNOWFLAKE_USER)"
  type        = string
  sensitive   = true
}

variable "snowflake_password" {
  description = "Snowflake password (from environment variable SNOWFLAKE_PASSWORD)"
  type        = string
  sensitive   = true
}

variable "snowflake_region" {
  description = "Snowflake region (from environment variable SNOWFLAKE_REGION)"
  type        = string
  default     = "us-east-1"
}

variable "preview_features_enabled" {
  description = "List of preview features to enable in Snowflake provider"
  type        = list(string)
  default     = ["snowflake_table_resource"]
}

# Project Configuration Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.project_name))
    error_message = "Project name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "my-organization"
}

variable "team_name" {
  description = "Name of the team"
  type        = string
  default     = "data-team"
}

# User Password Variables
variable "analyst_password" {
  description = "Password for analyst user"
  type        = string
  sensitive   = true
}

variable "engineer_password" {
  description = "Password for engineer user"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Password for admin user"
  type        = string
  sensitive   = true
} 