# =============================================================================
# SECURITY-FOCUSED EXAMPLE VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project (will be used as prefix for resources)"
  type        = string
  default     = "SECURE_CORP"
  
  validation {
    condition     = can(regex("^[A-Z0-9_]+$", var.project_name))
    error_message = "Project name must contain only uppercase letters, numbers, and underscores."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# =============================================================================
# AUTHENTICATION POLICIES (Provider 2.7.0)
# =============================================================================

variable "authentication_policies" {
  description = "Authentication policies for enhanced security controls"
  type = map(object({
    comment                    = optional(string, "Authentication policy managed by Terraform")
    authentication_methods     = optional(list(string), ["PASSWORD"])
    mfa_authentication_methods = optional(list(string), ["PASSWORD"])
    mfa_enrollment            = optional(string, "OPTIONAL")
    client_types              = optional(list(string), ["SNOWFLAKE_UI", "DRIVERS", "SNOWSQL"])
  }))
  default = {
    "MFA_REQUIRED_HUMANS" = {
      comment                    = "Enforce MFA for all human users"
      authentication_methods     = ["PASSWORD", "SAML"]
      mfa_authentication_methods = ["PASSWORD", "SAML"]
      mfa_enrollment            = "REQUIRED"
      client_types              = ["SNOWFLAKE_UI", "DRIVERS", "SNOWSQL"]
    }
    "SERVICE_ACCOUNTS_OAUTH" = {
      comment                = "Service accounts - OAuth/JWT only, no MFA"
      authentication_methods = ["OAUTH", "JWT"]
      mfa_enrollment        = "OPTIONAL"
      client_types          = ["DRIVERS", "SNOWSQL"]
    }
  }
}

# =============================================================================
# EXTERNAL OAUTH INTEGRATIONS (Provider 2.7.0)
# =============================================================================

variable "external_oauth_integrations" {
  description = "External OAuth integrations for workload identity federation"
  type = map(object({
    comment                     = optional(string, "External OAuth integration managed by Terraform")
    type                       = string
    enabled                    = optional(bool, true)
    external_oauth_type        = string
    external_oauth_issuer      = string
    external_oauth_jws_keys_url = optional(string)
    external_oauth_audience_list = optional(list(string))
    external_oauth_token_user_mapping_claim = optional(string, "sub")
    external_oauth_snowflake_user_mapping_attribute = optional(string, "LOGIN_NAME")
    external_oauth_scope_delimiter = optional(string, " ")
  }))
  default = {
    "GITHUB_ACTIONS" = {
      comment                = "GitHub Actions workload identity federation"
      type                  = "EXTERNAL_OAUTH"
      external_oauth_type   = "CUSTOM"
      external_oauth_issuer = "https://token.actions.githubusercontent.com"
      external_oauth_audience_list = ["https://github.com/your-org"]
      external_oauth_token_user_mapping_claim = "sub"
      external_oauth_snowflake_user_mapping_attribute = "LOGIN_NAME"
    }
    "AWS_WORKLOAD_IDENTITY" = {
      comment                = "AWS EKS workload identity federation"
      type                  = "EXTERNAL_OAUTH"
      external_oauth_type   = "CUSTOM"
      external_oauth_issuer = "https://oidc.eks.us-west-2.amazonaws.com/id/YOUR-CLUSTER-ID"
      external_oauth_audience_list = ["sts.amazonaws.com"]
      external_oauth_token_user_mapping_claim = "sub"
      external_oauth_snowflake_user_mapping_attribute = "LOGIN_NAME"
    }
  }
}

# =============================================================================
# SERVICE USERS CONFIGURATION
# =============================================================================

variable "service_users" {
  description = "Service users with RSA key-pair authentication"
  type = map(object({
    comment                = optional(string, "Service user managed by Terraform")
    default_role          = optional(string, "PUBLIC")
    default_warehouse     = optional(string)
    disabled              = optional(bool, false)
    display_name          = optional(string)
    email                 = optional(string)
    login_name            = optional(string)
    rsa_public_key        = optional(string, null)
    rsa_public_key_2      = optional(string, null)
    days_to_expiry        = optional(number, null)
  }))
  default = {
    "TERRAFORM_SERVICE" = {
      comment           = "Terraform automation service user"
      default_role      = "SYSADMIN"
      email            = "terraform@company.com"
      display_name     = "Terraform Service Account"
      days_to_expiry   = 365
      # rsa_public_key   = "base64_encoded_public_key_here"
    }
    "CI_CD_SERVICE" = {
      comment           = "CI/CD pipeline service user"
      default_role      = "TRANSFORMER_ROLE"
      email            = "cicd@company.com"
      display_name     = "CI/CD Service Account"
      days_to_expiry   = 180
      # rsa_public_key   = "base64_encoded_public_key_here"
    }
    "MONITORING_SERVICE" = {
      comment           = "Monitoring and alerting service user"
      default_role      = "READER"
      email            = "monitoring@company.com"
      display_name     = "Monitoring Service Account"
      days_to_expiry   = 90
      # rsa_public_key   = "base64_encoded_public_key_here"
    }
  }
}

# =============================================================================
# PAT TOKENS CONFIGURATION
# =============================================================================

variable "pat_tokens" {
  description = "Personal Access Tokens for service users"
  type = map(object({
    user_name                                = string
    comment                                 = optional(string, "PAT token managed by Terraform")
    days_to_expiry                         = optional(number, 90)
    disabled                               = optional(bool, false)
    role_restriction                       = optional(list(string), [])
    mins_to_bypass_network_policy_requirement = optional(number, null)
    expire_rotated_token_after_hours       = optional(number, 24)
  }))
  default = {
    "terraform_automation_token" = {
      user_name         = "TERRAFORM_SERVICE"
      comment          = "Token for Terraform automation"
      days_to_expiry   = 90
      role_restriction = ["SYSADMIN", "SECURITYADMIN"]
    }
    "cicd_pipeline_token" = {
      user_name         = "CI_CD_SERVICE"
      comment          = "Token for CI/CD pipeline"
      days_to_expiry   = 30
      role_restriction = ["TRANSFORMER_ROLE"]
    }
    "monitoring_token" = {
      user_name         = "MONITORING_SERVICE"
      comment          = "Token for monitoring and alerting"
      days_to_expiry   = 60
      role_restriction = ["READER"]
    }
  }
}

# =============================================================================
# NETWORK POLICIES CONFIGURATION
# =============================================================================

variable "network_rules" {
  description = "Network rules for IP-based access control"
  type = map(object({
    comment    = optional(string, "Network rule managed by Terraform")
    type       = string
    value_list = list(string)
    mode       = optional(string, "INGRESS")
  }))
  default = {
    "CORPORATE_NETWORK" = {
      comment    = "Corporate office IP ranges"
      type       = "IPV4"
      value_list = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      mode       = "INGRESS"
    }
    "CLOUD_PROVIDERS" = {
      comment    = "Trusted cloud provider IP ranges"
      type       = "IPV4"
      value_list = ["52.0.0.0/8", "54.0.0.0/8"]  # AWS examples
      mode       = "INGRESS"
    }
    "VPN_ENDPOINTS" = {
      comment    = "VPN endpoint IP addresses"
      type       = "IPV4"
      value_list = ["203.0.113.0/24"]  # Example VPN range
      mode       = "INGRESS"
    }
  }
}

variable "network_policies" {
  description = "Network policies for different user types"
  type = map(object({
    comment           = optional(string, "Network policy managed by Terraform")
    allowed_ip_list   = optional(list(string), [])
    blocked_ip_list   = optional(list(string), [])
    allowed_network_rule_list = optional(list(string), [])
    blocked_network_rule_list = optional(list(string), [])
  }))
  default = {
    "HUMAN_USERS_POLICY" = {
      comment = "Restrictive policy for human users"
      allowed_network_rule_list = ["CORPORATE_NETWORK", "VPN_ENDPOINTS"]
      blocked_ip_list = ["0.0.0.0/0"]  # Block all by default, allow via rules
    }
    "SERVICE_ACCOUNTS_POLICY" = {
      comment = "Policy for service accounts and automation"
      allowed_network_rule_list = ["CORPORATE_NETWORK", "CLOUD_PROVIDERS"]
      blocked_ip_list = []
    }
  }
}

# =============================================================================
# IP RANGES CONFIGURATION
# =============================================================================

variable "allowed_ip_ranges" {
  description = "IP ranges allowed by default network policy"
  type        = list(string)
  default     = [
    "10.0.0.0/8",      # Corporate network
    "172.16.0.0/12",   # Corporate network
    "192.168.0.0/16",  # Corporate network
  ]
}

variable "blocked_ip_ranges" {
  description = "IP ranges explicitly blocked"
  type        = list(string)
  default     = [
    "169.254.0.0/16",  # AWS metadata service
    "127.0.0.0/8",     # Localhost
  ]
}

# =============================================================================
# CUSTOM ROLES FOR SECURITY
# =============================================================================

variable "custom_roles" {
  description = "Custom roles for enhanced security management"
  type = map(object({
    comment = optional(string, "Custom role managed by Terraform")
  }))
  default = {
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
}
