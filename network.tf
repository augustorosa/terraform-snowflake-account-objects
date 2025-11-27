# =============================================================================
# NETWORK POLICIES AND RULES
# =============================================================================

# Create network rules for IP-based access control
# Network rules are stored in the central settings database under NETWORK schema
resource "snowflake_network_rule" "network_rules" {
  for_each = var.enable_network_policies ? var.network_rules : {}
  
  name       = "${local.base_prefix}_${each.key}_RULE"
  database   = var.enable_central_settings_db ? snowflake_database.central_settings[0].name : snowflake_database.tag_database[0].name
  schema     = var.enable_central_settings_db ? snowflake_schema.network_schema[0].name : snowflake_schema.tag_schema[0].name
  comment    = each.value.comment
  type       = each.value.type
  value_list = each.value.value_list
  mode       = each.value.mode

  depends_on = [
    snowflake_schema.network_schema,
    snowflake_schema.tag_schema
  ]
}

# Create network policies  
resource "snowflake_network_policy" "network_policies" {
  for_each = var.enable_network_policies ? var.network_policies : {}
  
  name                      = "${local.base_prefix}_${each.key}_POLICY"
  comment                   = each.value.comment
  allowed_ip_list          = each.value.allowed_ip_list
  blocked_ip_list          = each.value.blocked_ip_list
  allowed_network_rule_list = length(each.value.allowed_network_rule_list) > 0 ? [
    for rule_name in each.value.allowed_network_rule_list : 
    snowflake_network_rule.network_rules[rule_name].name
  ] : null
  blocked_network_rule_list = length(each.value.blocked_network_rule_list) > 0 ? [
    for rule_name in each.value.blocked_network_rule_list :
    snowflake_network_rule.network_rules[rule_name].name
  ] : null
  
  depends_on = [snowflake_network_rule.network_rules]
}

# Create default network policy if enabled
resource "snowflake_network_policy" "default_policy" {
  count = var.enable_network_policies && var.default_network_policy.enabled ? 1 : 0
  
  name            = "${local.base_prefix}_${var.default_network_policy.name}"
  comment         = var.default_network_policy.comment
  allowed_ip_list = var.default_network_policy.allowed_ip_list
  blocked_ip_list = var.default_network_policy.blocked_ip_list
}
