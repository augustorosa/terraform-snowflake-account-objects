# =============================================================================
# TEST CONFIGURATION VARIABLES
# =============================================================================

variable "snowflake_account" {
  description = "Snowflake account identifier (e.g., 'abc12345.us-east-1')"
  type        = string
  default     = null
  sensitive   = true
}

variable "snowflake_user" {
  description = "Snowflake username for authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "snowflake_password" {
  description = "Snowflake password for authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "snowflake_role" {
  description = "Snowflake role to use (requires ACCOUNTADMIN for full testing)"
  type        = string
  default     = "ACCOUNTADMIN"
}

variable "snowflake_warehouse" {
  description = "Default warehouse for Snowflake operations"
  type        = string
  default     = "COMPUTE_WH"
}

# Key-pair authentication variables (alternative to password)
variable "snowflake_private_key_path" {
  description = "Path to RSA private key file for key-pair authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "snowflake_private_key_passphrase" {
  description = "Passphrase for encrypted RSA private key"
  type        = string
  default     = null
  sensitive   = true
}

# Test control variables
variable "actually_deploy" {
  description = "Set to true to actually deploy resources (requires proper Snowflake credentials)"
  type        = bool
  default     = false
}

variable "auto_destroy_after_minutes" {
  description = "Automatically mark resources for cleanup after specified minutes (for safety)"
  type        = number
  default     = 60
} 