# =============================================================================
# SERVICE USERS WITH KEY-PAIR AUTHENTICATION
# =============================================================================

# Create service users with RSA key-pair authentication support
resource "snowflake_service_user" "service_users" {
  for_each = var.enable_key_pair_auth ? var.service_users : {}
  
  name              = each.key
  comment           = each.value.comment
  default_role      = each.value.default_role
  default_warehouse = each.value.default_warehouse
  disabled          = each.value.disabled
  display_name      = each.value.display_name != null ? each.value.display_name : each.key
  email             = each.value.email
  login_name        = each.value.login_name != null ? each.value.login_name : each.key
  
  # RSA public key authentication (primary key)  
  rsa_public_key = each.value.rsa_public_key
  
  # RSA public key authentication (secondary key for rotation)
  rsa_public_key_2 = each.value.rsa_public_key_2
  
  # Account expiry
  days_to_expiry = each.value.days_to_expiry
}

# =============================================================================
# PERSONAL ACCESS TOKENS (PAT)
# =============================================================================

# Create PAT tokens for service users
resource "snowflake_user_programmatic_access_token" "pat_tokens" {
  for_each = var.enable_pat_tokens ? var.pat_tokens : {}
  
  name    = each.key
  user    = each.value.user_name
  comment = each.value.comment
  
  # Token expiry and lifecycle
  days_to_expiry                         = each.value.days_to_expiry
  disabled                               = each.value.disabled
  expire_rotated_token_after_hours       = each.value.expire_rotated_token_after_hours
  
  # Security restrictions
  role_restriction                       = length(each.value.role_restriction) > 0 ? each.value.role_restriction : null
  mins_to_bypass_network_policy_requirement = each.value.mins_to_bypass_network_policy_requirement
  
  # Depend on service users if they're being created
  depends_on = [snowflake_service_user.service_users]
}

# =============================================================================
# AUTHENTICATION POLICIES
# =============================================================================

# Create authentication policies for enhanced security controls
resource "snowflake_authentication_policy" "auth_policies" {
  for_each = var.enable_authentication_policies ? var.authentication_policies : {}
  
  name    = "${local.base_prefix}_${each.key}_AUTH_POLICY"
  comment = each.value.comment
  
  authentication_methods     = each.value.authentication_methods
  mfa_authentication_methods = each.value.mfa_authentication_methods
  mfa_enrollment            = each.value.mfa_enrollment
  client_types              = each.value.client_types
}

# =============================================================================
# EXTERNAL OAUTH INTEGRATIONS
# =============================================================================

# Create external OAuth integrations for workload identity federation
resource "snowflake_external_oauth_integration" "oauth_integrations" {
  for_each = var.enable_external_oauth ? var.external_oauth_integrations : {}
  
  name    = "${local.base_prefix}_${each.key}_OAUTH"
  comment = each.value.comment
  
  type                        = each.value.type
  enabled                     = each.value.enabled
  external_oauth_type         = each.value.external_oauth_type
  external_oauth_issuer       = each.value.external_oauth_issuer
  external_oauth_jws_keys_url = each.value.external_oauth_jws_keys_url
  external_oauth_audience_list = each.value.external_oauth_audience_list
  external_oauth_token_user_mapping_claim = each.value.external_oauth_token_user_mapping_claim
  external_oauth_snowflake_user_mapping_attribute = each.value.external_oauth_snowflake_user_mapping_attribute
  external_oauth_scope_delimiter = each.value.external_oauth_scope_delimiter
}
