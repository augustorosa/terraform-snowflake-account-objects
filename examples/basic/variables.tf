# Snowflake Authentication Variables
variable "snowflake_organization" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name (without organization prefix)"
  type        = string
}

variable "snowflake_username" {
  description = "Snowflake username"
  type        = string
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
}

# Project Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Environment (dev, qa, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod"
  }
}

# Tagging Variables
variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "owner_email" {
  description = "Email of the resource owner"
  type        = string
  default     = "data-team@example.com"
} 