# =============================================================================
# SECURITY-FOCUSED EXAMPLE - PROVIDER 2.7.0 FEATURES
# =============================================================================
# This example demonstrates all the latest security features available in
# Snowflake Terraform Provider 2.7.0, focusing on account-level security objects.

terraform {
  required_version = ">= 1.5.7"
  
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.7.0"
    }
  }
}

# =============================================================================
# SECURITY-FIRST SNOWFLAKE ACCOUNT CONFIGURATION
# =============================================================================

module "snowflake_secure_account" {
  source = "../../"
  
  # =============================================================================
  # PROJECT CONFIGURATION
  # =============================================================================
  project_name = var.project_name
  environment  = var.environment
  
  # =============================================================================
  # SECURITY FEATURE FLAGS - ALL ENABLED
  # =============================================================================
  enable_rbac                    = true   # Role-based access control
  enable_tagging                 = true   # Resource governance
  enable_key_pair_auth          = true   # RSA key-pair authentication
  enable_pat_tokens             = true   # Personal Access Tokens
  enable_authentication_policies = true   # MFA enforcement (NEW in 2.7.0)
  enable_external_oauth         = true   # Workload identity federation (NEW in 2.7.0)
  enable_network_policies       = true   # IP-based access control
  enable_auto_classification    = true   # Data governance
  
  # Minimal infrastructure for security focus
  enable_databases        = false  # Focus on account-level security
  enable_warehouses       = false  # Focus on account-level security
  enable_data_loading     = false  # Focus on account-level security
  enable_resource_monitors = false # Focus on account-level security
  
  # =============================================================================
  # RBAC CONFIGURATION - SECURITY-FOCUSED ROLES
  # =============================================================================
  create_default_roles = true
  
  custom_roles = {
    "SECURITY_ADMIN" = {
      comment = "Enhanced security administration role"
    }
    "COMPLIANCE_AUDITOR" = {
      comment = "Read-only access for compliance auditing"
    }
    "SERVICE_ACCOUNT_MANAGER" = {
      comment = "Manages service accounts and authentication"
    }
  }
  
  role_grants = {
    "SECURITY_ADMIN" = {
      roles = ["SECURITYADMIN"]
      users = []
    }
    "COMPLIANCE_AUDITOR" = {
      roles = ["READER"]
      users = []
    }
    "SERVICE_ACCOUNT_MANAGER" = {
      roles = ["USERADMIN"]
      users = []
    }
  }
  
  # =============================================================================
  # AUTHENTICATION POLICIES (Provider 2.7.0)
  # =============================================================================
  authentication_policies = var.authentication_policies
  
  # =============================================================================
  # EXTERNAL OAUTH INTEGRATIONS (Provider 2.7.0)
  # =============================================================================
  external_oauth_integrations = var.external_oauth_integrations
  
  # =============================================================================
  # SERVICE USERS WITH KEY-PAIR AUTHENTICATION
  # =============================================================================
  service_users = var.service_users
  
  # =============================================================================
  # PAT TOKENS FOR PROGRAMMATIC ACCESS
  # =============================================================================
  pat_tokens = var.pat_tokens
  
  # =============================================================================
  # NETWORK POLICIES FOR IP RESTRICTIONS
  # =============================================================================
  network_rules = var.network_rules
  network_policies = var.network_policies
  
  default_network_policy = {
    enabled             = true
    name               = "DEFAULT_SECURITY_POLICY"
    comment            = "Default restrictive network policy for enhanced security"
    allowed_ip_list    = var.allowed_ip_ranges
    blocked_ip_list    = var.blocked_ip_ranges
  }
  
  # =============================================================================
  # AUTO-CLASSIFICATION FOR DATA GOVERNANCE
  # =============================================================================
  classification_config = {
    minimum_object_age_days = 0
    maximum_validity_days   = 30
    auto_tag               = true
    enable_system_tags     = true
    custom_tag_mappings    = []
  }
  
  # =============================================================================
  # TAGGING FOR SECURITY GOVERNANCE
  # =============================================================================
  create_tag_schema = true
  
  governance_tags = {
    "SECURITY_CLASSIFICATION" = {
      allowed_values = ["PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"]
      comment       = "Data security classification level"
    }
    "COMPLIANCE_SCOPE" = {
      allowed_values = ["SOX", "PCI", "HIPAA", "GDPR", "NONE"]
      comment       = "Regulatory compliance requirements"
    }
    "ACCESS_LEVEL" = {
      allowed_values = ["PUBLIC", "AUTHENTICATED", "AUTHORIZED", "PRIVILEGED"]
      comment       = "Required access level for data"
    }
  }
  
  operational_tags = {
    "SECURITY_CONTACT" = {
      allowed_values = []
      comment       = "Security team contact for this resource"
    }
    "AUDIT_FREQUENCY" = {
      allowed_values = ["DAILY", "WEEKLY", "MONTHLY", "QUARTERLY", "ANNUALLY"]
      comment       = "Required audit frequency"
    }
  }
  
  technical_tags = {
    "ENCRYPTION_REQUIRED" = {
      allowed_values = ["TRUE", "FALSE"]
      comment       = "Whether encryption is required"
    }
    "MFA_REQUIRED" = {
      allowed_values = ["TRUE", "FALSE"]
      comment       = "Whether MFA is required for access"
    }
  }
}

# =============================================================================
# OUTPUTS FOR SECURITY MONITORING
# =============================================================================

output "security_summary" {
  description = "Summary of implemented security features"
  value = {
    authentication_policies_count = length(module.snowflake_secure_account.authentication_policies)
    oauth_integrations_count     = length(module.snowflake_secure_account.external_oauth_integrations)
    service_users_count          = length(module.snowflake_secure_account.service_users)
    pat_tokens_count            = length(module.snowflake_secure_account.pat_tokens)
    network_policies_count      = length(module.snowflake_secure_account.network_policies)
    custom_roles_count          = length(var.custom_roles)
  }
}

output "authentication_policies" {
  description = "Created authentication policies"
  value       = module.snowflake_secure_account.authentication_policies
}

output "oauth_integrations" {
  description = "Created OAuth integrations for workload identity"
  value       = module.snowflake_secure_account.external_oauth_integrations
}

output "service_users" {
  description = "Created service users"
  value       = module.snowflake_secure_account.service_users
}

output "network_policies" {
  description = "Created network policies"
  value       = module.snowflake_secure_account.network_policies
}

output "security_setup_guide" {
  description = "Next steps for security configuration"
  value = [
    "1. Configure your identity provider to use the OAuth integrations",
    "2. Distribute RSA private keys securely to service accounts",
    "3. Test PAT token authentication with network policies",
    "4. Apply authentication policies to enforce MFA",
    "5. Monitor authentication logs for security events",
    "6. Set up automated key rotation procedures",
    "7. Configure Trust Center notifications for violations"
  ]
}
