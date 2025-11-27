# =============================================================================
# SNOWFLAKE PROVIDER CONFIGURATION FOR TESTING
# =============================================================================

provider "snowflake" {
  # Authentication can be provided via:
  # 1. Environment variables (recommended for testing)
  # 2. Provider configuration (not recommended for production)
  # 3. Config file (~/.snowflake/config)

  # Option 1: Environment Variables (RECOMMENDED)
  # Set these environment variables before running terraform:
  # export SNOWFLAKE_ACCOUNT="your-account-identifier"
  # export SNOWFLAKE_USER="your-username" 
  # export SNOWFLAKE_PASSWORD="your-password"
  # export SNOWFLAKE_ROLE="ACCOUNTADMIN"
  # export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"

  # Option 2: Provider Configuration (for testing only)
  # Using direct configuration for comprehensive testing:
  account  = var.snowflake_account
  user     = var.snowflake_user
  password = var.snowflake_password
  role     = var.snowflake_role

  # Option 3: Key-pair authentication (for production)
  # account              = var.snowflake_account
  # user                 = var.snowflake_user
  # private_key_path     = var.snowflake_private_key_path
  # private_key_passphrase = var.snowflake_private_key_passphrase
  # role                 = var.snowflake_role
} 