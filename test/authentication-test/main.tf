# =============================================================================
# COMPREHENSIVE AUTHENTICATION FEATURES TEST
# =============================================================================
# This configuration tests all authentication features:
# - RSA key-pair authentication for service users
# - Personal Access Token (PAT) creation
# - Network policies and rules
# - Complete integration test

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.7.0"
    }
  }
}

# Use the module with comprehensive authentication testing
module "snowflake_auth_test" {
  source = "../../"

  # =============================================================================
  # PROJECT CONFIGURATION
  # =============================================================================
  project_name = "AUTH_TEST"
  environment  = "dev"

  # =============================================================================
  # FEATURE FLAGS - AUTHENTICATION FOCUSED
  # =============================================================================
  enable_rbac              = true  # Need roles for testing
  enable_tagging           = true  # For proper resource organization
  enable_databases         = false # Not needed for auth testing
  enable_warehouses        = false # Not needed for auth testing
  enable_data_loading      = false # Not needed for auth testing
  enable_resource_monitors = false # Not needed for auth testing

  # AUTHENTICATION FEATURES - ALL ENABLED FOR TESTING
  enable_key_pair_auth       = true
  enable_pat_tokens          = true
  enable_network_policies    = true
  enable_auto_classification = false # Not needed for auth testing

  # =============================================================================
  # NETWORK POLICIES CONFIGURATION
  # =============================================================================

  # Enable default network policy with permissive settings for testing
  default_network_policy = {
    enabled         = true
    name            = "TEST_DEFAULT_POLICY"
    comment         = "Test default network policy - allows all IPs for testing"
    allowed_ip_list = ["0.0.0.0/0"] # Allow all IPs for testing
    blocked_ip_list = []
  }

  # Custom network rules for testing
  network_rules = {
    "CORPORATE" = {
      comment    = "Corporate network range"
      type       = "IPV4"
      value_list = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      mode       = "INGRESS"
    }
    "GITHUB_ACTIONS" = {
      comment    = "GitHub Actions IP ranges for CI/CD"
      type       = "IPV4"
      value_list = ["140.82.112.0/20", "143.55.64.0/20", "192.30.252.0/22"]
      mode       = "INGRESS"
    }
    "LOCAL_DEV" = {
      comment    = "Local development IPs"
      type       = "IPV4"
      value_list = ["127.0.0.1/32"]
      mode       = "INGRESS"
    }
  }

  # Custom network policies for different use cases
  network_policies = {
    "SERVICE_ACCOUNTS" = {
      comment                   = "Network policy for service accounts and automation"
      allowed_ip_list           = []
      blocked_ip_list           = []
      allowed_network_rule_list = ["CORPORATE", "GITHUB_ACTIONS"]
      blocked_network_rule_list = []
    }
    "HUMAN_USERS" = {
      comment                   = "Network policy for human users"
      allowed_ip_list           = []
      blocked_ip_list           = []
      allowed_network_rule_list = ["CORPORATE", "LOCAL_DEV"]
      blocked_network_rule_list = []
    }
  }

  # =============================================================================
  # SERVICE USERS WITH RSA KEY-PAIR AUTHENTICATION
  # =============================================================================

  service_users = {
    "TERRAFORM_SERVICE" = {
      comment           = "Terraform automation service user - TEST"
      default_role      = "AUTH_TEST_TEST_ADMIN_ROLE"
      default_warehouse = null
      email             = "terraform-test@company.local"
      display_name      = "Terraform Test Service Account"
      # Note: In real usage, you would provide actual RSA public keys here
      # rsa_public_key   = "your_base64_encoded_public_key_here"
      # rsa_public_key_2 = "your_secondary_key_for_rotation"
      days_to_expiry = 90 # Short expiry for testing
    }
    "DBT_SERVICE" = {
      comment           = "dbt transformation service user - TEST"
      default_role      = "AUTH_TEST_TEST_WRITER_ROLE"
      default_warehouse = null
      email             = "dbt-test@company.local"
      display_name      = "dbt Test Service Account"
      # Note: Keys would be provided in real usage
      days_to_expiry = 30
    }
    "MONITORING_SERVICE" = {
      comment           = "Monitoring and alerting service user - TEST"
      default_role      = "AUTH_TEST_TEST_READER_ROLE"
      default_warehouse = null
      email             = "monitoring-test@company.local"
      display_name      = "Monitoring Test Service Account"
      days_to_expiry    = 180
    }
  }

  # =============================================================================
  # PERSONAL ACCESS TOKENS (PAT)
  # =============================================================================

  pat_tokens = {
    "terraform_automation_token" = {
      user_name                                 = "TERRAFORM_SERVICE"
      comment                                   = "PAT token for Terraform automation - TEST"
      days_to_expiry                            = 30 # Short expiry for testing
      disabled                                  = false
      role_restriction                          = ["AUTH_TEST_TEST_ADMIN_ROLE", "SYSADMIN"]
      mins_to_bypass_network_policy_requirement = 60 # Allow 1 hour bypass for emergencies
      expire_rotated_token_after_hours          = 24
    }
    "dbt_ci_token" = {
      user_name                                 = "DBT_SERVICE"
      comment                                   = "PAT token for dbt CI/CD pipeline - TEST"
      days_to_expiry                            = 14 # Very short for testing
      disabled                                  = false
      role_restriction                          = ["AUTH_TEST_TEST_WRITER_ROLE"]
      mins_to_bypass_network_policy_requirement = 30
      expire_rotated_token_after_hours          = 12
    }
    "monitoring_readonly_token" = {
      user_name                                 = "MONITORING_SERVICE"
      comment                                   = "PAT token for monitoring queries - TEST"
      days_to_expiry                            = 60
      disabled                                  = false
      role_restriction                          = ["AUTH_TEST_TEST_READER_ROLE"]
      mins_to_bypass_network_policy_requirement = null # No bypass allowed
      expire_rotated_token_after_hours          = 6
    }
  }

  # =============================================================================
  # RBAC CONFIGURATION FOR TESTING
  # =============================================================================
  create_default_roles = true

  # Additional custom roles for comprehensive testing
  custom_functional_roles = {
    TOKEN_ADMIN = {
      comment = "Role for managing PAT tokens and authentication - TEST"
    }
    SECURITY_AUDITOR = {
      comment = "Role for security auditing and monitoring - TEST"
    }
  }

  # =============================================================================
  # TAGGING FOR PROPER RESOURCE ORGANIZATION
  # =============================================================================
  create_tag_schema = true
}