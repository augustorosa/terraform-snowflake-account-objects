# =============================================================================
# RBAC (ROLE-BASED ACCESS CONTROL)
# Per-Environment Architecture: 7 roles per environment + 1 cross-environment
# =============================================================================
# Functional Roles (What you can DO - inherit from each other):
#   - {ENV}_PROJECT_READER_RL
#   - {ENV}_PROJECT_WRITER_RL (inherits READER)
#   - {ENV}_PROJECT_ADMIN_RL (inherits WRITER → READER)
#
# Data Access Roles (What data you can ACCESS - granted to functional):
#   - {ENV}_PROJECT_INGEST_RL      → INSERT/COPY to RAW only
#   - {ENV}_PROJECT_TRANSFORM_RL   → READ RAW, WRITE INT+ANL
#   - {ENV}_PROJECT_ANALYSIS_RL    → READ ANL only
#   - {ENV}_PROJECT_SCIENTIST_RL   → READ RAW+INT+ANL (all read-only)
#
# Cross-Environment Role:
#   - PROJECT_ADMIN_RL (inherits from all env admins, inherits to SYSADMIN)
# =============================================================================

# =============================================================================
# PER-ENVIRONMENT FUNCTIONAL ROLES
# =============================================================================

resource "snowflake_account_role" "functional_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "READER", # Can read data
    "WRITER", # Can read and write data
    "ADMIN"   # Can read, write, and administer
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_RL"
  comment = "Functional role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# =============================================================================
# PER-ENVIRONMENT DATA ACCESS ROLES
# =============================================================================

resource "snowflake_account_role" "data_access_roles" {
  for_each = var.enable_rbac && var.create_default_roles ? toset([
    "INGEST",    # Access to RAW layer only (for ingestion)
    "TRANSFORM", # Access to RAW (read) + INT+ANL (write)
    "ANALYSIS",  # Access to ANL layer only (read)
    "SCIENTIST"  # Access to RAW+INT+ANL (all read-only)
  ]) : toset([])

  name    = "${local.base_prefix}_${each.key}_RL"
  comment = "Data access role: ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform"
}

# =============================================================================
# CROSS-ENVIRONMENT PROJECT ADMIN ROLE
# =============================================================================

resource "snowflake_account_role" "project_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  name    = "${upper(var.project_name)}_ADMIN_RL"
  comment = "Cross-environment project administrator role - Full access to all environments - Managed by Terraform"
}

# =============================================================================
# CUSTOM ROLES (user-defined)
# =============================================================================

resource "snowflake_account_role" "custom_roles" {
  for_each = var.enable_rbac ? var.custom_roles : {}

  name    = "${local.base_prefix}_${upper(each.key)}_RL"
  comment = each.value.comment != "" ? each.value.comment : "Custom role: ${each.key} - Managed by Terraform"
}

# =============================================================================
# FUNCTIONAL ROLE INHERITANCE (READER → WRITER → ADMIN)
# =============================================================================

# READER → WRITER (READER inherits from WRITER)
resource "snowflake_grant_account_role" "reader_to_writer" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["READER"].name
  parent_role_name = snowflake_account_role.functional_roles["WRITER"].name

  depends_on = [snowflake_account_role.functional_roles]
}

# WRITER → ADMIN (WRITER inherits from ADMIN)
resource "snowflake_grant_account_role" "writer_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["WRITER"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [snowflake_account_role.functional_roles]
}

# =============================================================================
# DATA ACCESS ROLE GRANTS TO FUNCTIONAL ROLES
# =============================================================================

# READER gets ANALYSIS_RL (read-only access to ANL layer)
resource "snowflake_grant_account_role" "analysis_to_reader" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["ANALYSIS"].name
  parent_role_name = snowflake_account_role.functional_roles["READER"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

# WRITER gets TRANSFORM_RL (read RAW, write INT+ANL)
# Note: WRITER also inherits ANALYSIS_RL via READER inheritance
resource "snowflake_grant_account_role" "transform_to_writer" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["TRANSFORM"].name
  parent_role_name = snowflake_account_role.functional_roles["WRITER"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

# ADMIN gets ALL data access roles
resource "snowflake_grant_account_role" "ingest_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["INGEST"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

resource "snowflake_grant_account_role" "transform_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["TRANSFORM"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

resource "snowflake_grant_account_role" "analysis_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["ANALYSIS"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

resource "snowflake_grant_account_role" "scientist_to_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.data_access_roles["SCIENTIST"].name
  parent_role_name = snowflake_account_role.functional_roles["ADMIN"].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.data_access_roles
  ]
}

# =============================================================================
# CROSS-ENVIRONMENT PROJECT_ADMIN_RL INHERITANCE
# =============================================================================

# PROJECT_ADMIN_RL inherits from current environment's ADMIN_RL
resource "snowflake_grant_account_role" "env_admin_to_project_admin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.functional_roles["ADMIN"].name
  parent_role_name = snowflake_account_role.project_admin[0].name

  depends_on = [
    snowflake_account_role.functional_roles,
    snowflake_account_role.project_admin
  ]
}

# PROJECT_ADMIN_RL inherits to SYSADMIN
resource "snowflake_grant_account_role" "project_admin_to_sysadmin" {
  count = var.enable_rbac && var.create_default_roles ? 1 : 0

  role_name        = snowflake_account_role.project_admin[0].name
  parent_role_name = "SYSADMIN"

  depends_on = [snowflake_account_role.project_admin]
}

# =============================================================================
# DATABASE PERMISSIONS FOR DATA ACCESS ROLES
# =============================================================================

# Helper local to identify database layers
locals {
  # Map database keys to their layer types
  database_layers = var.enable_databases ? {
    for db_key, db_config in var.databases :
    db_key => upper(db_config.suffix != "" ? db_config.suffix : db_key)
  } : {}

  # Identify RAW databases
  raw_databases = {
    for db_key, layer in local.database_layers :
    db_key => layer
    if layer == "RAW"
  }

  # Identify INT databases
  int_databases = {
    for db_key, layer in local.database_layers :
    db_key => layer
    if layer == "INT"
  }

  # Identify ANL databases
  anl_databases = {
    for db_key, layer in local.database_layers :
    db_key => layer
    if layer == "ANL"
  }
}

# INGEST_RL: USAGE on RAW databases only
resource "snowflake_grant_privileges_to_account_role" "ingest_raw_usage" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? local.raw_databases : {}

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.data_access_roles["INGEST"].name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.databases[each.key].name
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases
  ]
}

# INGEST_RL: INSERT, CREATE TABLE, CREATE STAGE on RAW schemas
resource "snowflake_grant_privileges_to_account_role" "ingest_raw_schema_privileges" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? {
    for schema_key, schema in local.all_schemas :
    schema_key => schema
    if contains(keys(local.raw_databases), schema.database_key)
  } : {}

  privileges        = ["USAGE", "CREATE TABLE", "CREATE STAGE", "INSERT"]
  account_role_name = snowflake_account_role.data_access_roles["INGEST"].name
  on_schema {
    schema_name = "${snowflake_database.databases[each.value.database_key].name}.${snowflake_schema.schemas[each.key].name}"
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases,
    snowflake_schema.schemas
  ]
}

# TRANSFORM_RL: USAGE on RAW, INT, ANL databases
resource "snowflake_grant_privileges_to_account_role" "transform_database_usage" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? merge(
    local.raw_databases,
    local.int_databases,
    local.anl_databases
  ) : {}

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.data_access_roles["TRANSFORM"].name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.databases[each.key].name
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases
  ]
}

# TRANSFORM_RL: SELECT on RAW schemas, ALL on INT+ANL schemas
resource "snowflake_grant_privileges_to_account_role" "transform_raw_schema_select" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? {
    for schema_key, schema in local.all_schemas :
    schema_key => schema
    if contains(keys(local.raw_databases), schema.database_key)
  } : {}

  privileges        = ["USAGE", "SELECT"]
  account_role_name = snowflake_account_role.data_access_roles["TRANSFORM"].name
  on_schema {
    schema_name = "${snowflake_database.databases[each.value.database_key].name}.${snowflake_schema.schemas[each.key].name}"
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases,
    snowflake_schema.schemas
  ]
}

resource "snowflake_grant_privileges_to_account_role" "transform_int_anl_schema_all" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? {
    for schema_key, schema in local.all_schemas :
    schema_key => schema
    if contains(keys(local.int_databases), schema.database_key) || contains(keys(local.anl_databases), schema.database_key)
  } : {}

  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  account_role_name = snowflake_account_role.data_access_roles["TRANSFORM"].name
  on_schema {
    schema_name = "${snowflake_database.databases[each.value.database_key].name}.${snowflake_schema.schemas[each.key].name}"
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases,
    snowflake_schema.schemas
  ]
}

# ANALYSIS_RL: USAGE on ANL databases only
resource "snowflake_grant_privileges_to_account_role" "analysis_anl_usage" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? local.anl_databases : {}

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.data_access_roles["ANALYSIS"].name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.databases[each.key].name
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases
  ]
}

# ANALYSIS_RL: SELECT on ANL schemas
resource "snowflake_grant_privileges_to_account_role" "analysis_anl_schema_select" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? {
    for schema_key, schema in local.all_schemas :
    schema_key => schema
    if contains(keys(local.anl_databases), schema.database_key)
  } : {}

  privileges        = ["USAGE", "SELECT"]
  account_role_name = snowflake_account_role.data_access_roles["ANALYSIS"].name
  on_schema {
    schema_name = "${snowflake_database.databases[each.value.database_key].name}.${snowflake_schema.schemas[each.key].name}"
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases,
    snowflake_schema.schemas
  ]
}

# SCIENTIST_RL: USAGE on RAW, INT, ANL databases (all read-only)
resource "snowflake_grant_privileges_to_account_role" "scientist_database_usage" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? merge(
    local.raw_databases,
    local.int_databases,
    local.anl_databases
  ) : {}

  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.data_access_roles["SCIENTIST"].name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.databases[each.key].name
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases
  ]
}

# SCIENTIST_RL: SELECT on all schemas (RAW, INT, ANL)
resource "snowflake_grant_privileges_to_account_role" "scientist_schema_select" {
  for_each = var.enable_rbac && var.create_default_roles && var.enable_databases ? {
    for schema_key, schema in local.all_schemas :
    schema_key => schema
    if contains(keys(local.raw_databases), schema.database_key) ||
    contains(keys(local.int_databases), schema.database_key) ||
    contains(keys(local.anl_databases), schema.database_key)
  } : {}

  privileges        = ["USAGE", "SELECT"]
  account_role_name = snowflake_account_role.data_access_roles["SCIENTIST"].name
  on_schema {
    schema_name = "${snowflake_database.databases[each.value.database_key].name}.${snowflake_schema.schemas[each.key].name}"
  }

  depends_on = [
    snowflake_account_role.data_access_roles,
    snowflake_database.databases,
    snowflake_schema.schemas
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
    contains(["INGEST", "TRANSFORM", "ANALYSIS", "SCIENTIST"], each.value.inherit_from) && var.create_default_roles
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
