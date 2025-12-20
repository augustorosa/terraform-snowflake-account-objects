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
