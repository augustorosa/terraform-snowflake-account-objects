# =============================================================================
# RBAC (ROLE-BASED ACCESS CONTROL)
# =============================================================================

# Create functional roles (what you can DO)
resource "snowflake_account_role" "functional_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "READER",    # Can read data
    "WRITER",    # Can read and write data  
    "ADMIN"      # Can read, write, and administer
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_ROLE"
  comment = "Functional role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# Create data access roles (what data you can access)
resource "snowflake_account_role" "data_access_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "ALL_DATA",      # Access to RAW, PREPARE, ANALYSIS
    "ANALYSIS_ONLY",  # Access to ANALYSIS layer only
    "INGEST_ONLY"    # Access to RAW layer only (for ingestion)
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_ROLE"
  comment = "Data access role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# Create custom functional roles
resource "snowflake_account_role" "custom_functional_roles" {
  for_each = var.enable_rbac ? var.custom_functional_roles : {}

  name    = "${local.base_prefix}_${upper(each.key)}_ROLE"
  comment = each.value.comment != "" ? each.value.comment : "Custom functional role: ${each.key} - Managed by Terraform"
}

# Create custom data access roles
resource "snowflake_account_role" "custom_data_access_roles" {
  for_each = var.enable_rbac ? var.custom_data_access_roles : {}

  name    = "${local.base_prefix}_${upper(each.key)}_DATA_ROLE"
  comment = each.value.comment != "" ? each.value.comment : "Custom data access role: ${each.key} - Managed by Terraform"
}

# Grant ADMIN role to SYSADMIN (SYSADMIN inherits ADMIN)
resource "snowflake_grant_account_role" "admin_to_sysadmin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["ADMIN"].name
  parent_role_name = "SYSADMIN"

  depends_on = [snowflake_account_role.functional_roles]
}

# Create proper inheritance chain: READER -> WRITER -> ADMIN
resource "snowflake_grant_account_role" "writer_inherits_reader" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["READER"].name
  parent_role_name = snowflake_account_role.functional_roles["WRITER"].name

  depends_on = [snowflake_account_role.functional_roles]
}

resource "snowflake_grant_account_role" "admin_inherits_writer" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["WRITER"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [snowflake_account_role.functional_roles]
}

# Grant data access roles to ADMIN (ADMIN gets all data access)
resource "snowflake_grant_account_role" "all_data_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["ALL_DATA"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

resource "snowflake_grant_account_role" "analysis_only_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["ANALYSIS_ONLY"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

resource "snowflake_grant_account_role" "ingest_only_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["INGEST_ONLY"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

# =============================================================================
# CUSTOM ROLE INHERITANCE
# =============================================================================

# Grant custom functional roles to their parent roles (if inherit_from is specified)
resource "snowflake_grant_account_role" "custom_role_inheritance" {
  for_each = {
    for k, v in var.custom_functional_roles : k => v
    if var.enable_rbac && v.inherit_from != ""
  }

  role_name        = snowflake_account_role.custom_functional_roles[each.key].name
  parent_role_name = each.value.inherit_from

  depends_on = [snowflake_account_role.custom_functional_roles]
}
