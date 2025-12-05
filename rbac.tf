# =============================================================================
# RBAC (ROLE-BASED ACCESS CONTROL)
# Simplified architecture per RBAC_ARCHITECTURE.md
# 3 Functional Roles + 3 Data Access Roles = 6 Total
# =============================================================================

# Functional Roles (What you can DO)
resource "snowflake_account_role" "functional_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "READER", # Can read data
    "WRITER", # Can read and write data
    "ADMIN"   # Can read, write, and administer
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_RL"
  comment = "Functional role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# Data Access Roles (What data you can access)
resource "snowflake_account_role" "data_access_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "ALL_DATA",      # Access to RAW, PREPARE, ANALYSIS
    "ANALYSIS_ONLY", # Access to ANALYSIS layer only
    "INGEST_ONLY"    # Access to RAW layer only (for ingestion)
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_RL"
  comment = "Data access role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# Create custom roles (user-defined - for complex needs like DEVELOPER, DATA_ENGINEER, etc.)
resource "snowflake_account_role" "custom_roles" {
  for_each = var.enable_rbac ? var.custom_roles : {}

  name    = "${local.base_prefix}_${upper(each.key)}_RL"
  comment = each.value.comment != "" ? each.value.comment : "Custom role: ${each.key} - Managed by Terraform"
}

# =============================================================================
# ROLE HIERARCHY (per RBAC_ARCHITECTURE.md)
# Proper inheritance chain: READER → WRITER → ADMIN → SYSADMIN
# =============================================================================

# ADMIN → SYSADMIN (top of hierarchy)
resource "snowflake_grant_account_role" "admin_to_sysadmin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["ADMIN"].name
  parent_role_name = "SYSADMIN"

  depends_on = [snowflake_account_role.functional_roles]
}

# WRITER → ADMIN (inherits from WRITER)
resource "snowflake_grant_account_role" "writer_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["WRITER"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [snowflake_account_role.functional_roles]
}

# READER → WRITER (inherits from READER)
resource "snowflake_grant_account_role" "reader_to_writer" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["READER"].name
  parent_role_name = snowflake_account_role.functional_roles["WRITER"].name

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

# Grant custom roles to their parent roles (if inherit_from is specified)
resource "snowflake_grant_account_role" "custom_role_inheritance" {
  for_each = {
    for k, v in var.custom_roles : k => v
    if var.enable_rbac && v.inherit_from != ""
  }

  role_name = snowflake_account_role.custom_roles[each.key].name
  # Try to find parent in functional roles, data access roles, custom roles, or use as system role name
  parent_role_name = (
    contains(["READER", "WRITER", "ADMIN"], each.value.inherit_from) && var.create_default_roles
    ? snowflake_account_role.functional_roles[each.value.inherit_from].name :
    contains(["ALL_DATA", "ANALYSIS_ONLY", "INGEST_ONLY"], each.value.inherit_from) && var.create_default_roles
    ? snowflake_account_role.data_access_roles[each.value.inherit_from].name :
    contains(keys(var.custom_roles), each.value.inherit_from)
    ? snowflake_account_role.custom_roles[each.value.inherit_from].name :
    each.value.inherit_from # System role (SYSADMIN, SECURITYADMIN, PUBLIC, etc.)
  )

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles,
    snowflake_account_role.custom_roles
  ]
}
