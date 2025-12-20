# =============================================================================
# Comprehensive Example: Full-Featured Snowflake Account Objects
# =============================================================================
# This example demonstrates ALL module features including:
# - RBAC with functional and data access roles
# - 3-layer data architecture (RAW, PREPARE, ANALYSIS)
# - Auto-tagging system with tag associations
# - Central settings database
# - Network policies and rules
# - Resource monitors
# - Warehouses for different workloads
# =============================================================================

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.11"
    }
  }
}

# Configure Snowflake Provider
provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.snowflake_account
  user              = var.snowflake_username
  password          = var.snowflake_password
  role              = var.snowflake_role != null ? var.snowflake_role : "ACCOUNTADMIN"
  warehouse         = var.snowflake_warehouse != null ? var.snowflake_warehouse : null

  preview_features_enabled = var.preview_features_enabled

  # Workaround for macOS TLS certificate verification issues
  # Remove this in production and ensure proper certificate chain
  insecure_mode = true
}

# Local variables for naming
locals {
  env_prefix = {
    dev  = "DEV"
    qa   = "QA"
    prod = "PRD"
  }
}

# =============================================================================
# MAIN MODULE - Full Configuration
# =============================================================================

module "snowflake_account_objects" {
  source = "../../"

  # -----------------------------------------------------------------------------
  # Core Configuration
  # -----------------------------------------------------------------------------
  project_name = var.project_name
  environment  = var.environment

  # -----------------------------------------------------------------------------
  # Feature Flags - Enable all features for comprehensive testing
  # -----------------------------------------------------------------------------
  enable_rbac                = true
  enable_tagging             = true
  enable_databases           = true
  enable_warehouses          = true
  enable_data_loading        = true
  enable_resource_monitors   = true
  enable_network_policies    = var.enable_network_policies
  enable_central_settings_db = true
  enable_auto_classification = true # Enterprise Edition enabled

  # Tag Configuration
  create_tag_schema       = true
  auto_apply_tags         = true
  use_central_db_for_tags = false # Use legacy tag database for now

  # -----------------------------------------------------------------------------
  # RBAC Configuration
  # -----------------------------------------------------------------------------
  create_default_roles = true

  custom_roles = {
    data_scientist = {
      comment      = "Data scientist role with read access to all layers"
      inherit_from = "READER"
    }
    ml_engineer = {
      comment      = "ML engineer role with write access"
      inherit_from = "WRITER"
    }
    platform_admin = {
      comment      = "Platform administrator role"
      inherit_from = "ADMIN"
    }
  }

  # -----------------------------------------------------------------------------
  # Database Configuration - 3-Layer Architecture
  # -----------------------------------------------------------------------------
  # Multi-database approach: One database per layer
  # Pattern: PROJECT_ENV_LAYER_DB (e.g., ULONO_DEV_RAW_DB, ULONO_DEV_ANL_DB)
  # Schemas inside RAW are for source systems (SALESFORCE, MYSQL, etc.)
  # Schemas inside ANL are for business domains (CUSTOMER, PRODUCT, etc.)
  databases = {
    raw = {
      comment                     = "Raw data layer - Source system schemas (SALESFORCE, MYSQL, etc.)"
      suffix                      = "RAW"
      data_retention_days         = var.data_retention_days
      enable_3_layer_architecture = false
      create_layer_info_views     = false
    }
    int = {
      comment                       = "Integration layer - Transformed and enriched data"
      suffix                        = "INT"
      data_retention_days           = var.data_retention_days
      enable_3_layer_architecture   = false
      analysis_layer_managed_access = true
      create_layer_info_views       = false
    }
    anl = {
      comment                      = "Analysis layer - Business-ready data for reporting"
      suffix                       = "ANL"
      data_retention_days          = var.data_retention_days
      enable_3_layer_architecture  = false
      prepare_layer_managed_access = true
      prepare_layer_transient      = false
      create_layer_info_views      = false
    }
  }

  # -----------------------------------------------------------------------------
  # Warehouse Configuration
  # -----------------------------------------------------------------------------
  warehouses = {
    etl = {
      size                                = "X-SMALL"
      min_cluster_count                   = 1
      max_cluster_count                   = 2
      scaling_policy                      = "STANDARD"
      auto_suspend                        = 60
      auto_resume                         = true
      initially_suspended                 = true
      comment                             = "ETL processing warehouse"
      resource_monitor                    = ""
      enable_query_acceleration           = false
      query_acceleration_max_scale_factor = 8
    }
    analytics = {
      size                                = "SMALL"
      min_cluster_count                   = 1
      max_cluster_count                   = 3
      scaling_policy                      = "STANDARD"
      auto_suspend                        = 300
      auto_resume                         = true
      initially_suspended                 = true
      comment                             = "Analytics and BI warehouse"
      resource_monitor                    = ""
      enable_query_acceleration           = true
      query_acceleration_max_scale_factor = 8
    }
    adhoc = {
      size                                = "X-SMALL"
      min_cluster_count                   = 1
      max_cluster_count                   = 1
      scaling_policy                      = "ECONOMY"
      auto_suspend                        = 120
      auto_resume                         = true
      initially_suspended                 = true
      comment                             = "Ad-hoc queries warehouse"
      resource_monitor                    = ""
      enable_query_acceleration           = false
      query_acceleration_max_scale_factor = 8
    }
  }

  # -----------------------------------------------------------------------------
  # Resource Monitors - Cost Control
  # -----------------------------------------------------------------------------
  resource_monitors = {
    monthly_limit = {
      credit_quota    = var.monthly_credit_quota
      frequency       = "MONTHLY"
      start_timestamp = "" # Will default to current timestamp
      end_timestamp   = ""
      notify_triggers = [50, 75, 90, 100]
      notify_users    = []
    }
  }

  # -----------------------------------------------------------------------------
  # Network Policies (Optional - enable via variable)
  # -----------------------------------------------------------------------------
  network_rules = var.enable_network_policies ? {
    office_network = {
      type       = "IPV4"
      mode       = "INGRESS"
      value_list = var.allowed_ip_ranges
      comment    = "Office and VPN IP ranges"
    }
  } : {}

  network_policies = var.enable_network_policies ? {
    default_policy = {
      allowed_network_rule_list = ["office_network"]
      blocked_network_rule_list = []
      allowed_ip_list           = []
      blocked_ip_list           = []
      comment                   = "Default network access policy"
    }
  } : {}

  # -----------------------------------------------------------------------------
  # Service Users & Authentication
  # -----------------------------------------------------------------------------
  service_users = var.service_users
  pat_tokens    = var.pat_tokens

  # -----------------------------------------------------------------------------
  # Data Loading Configuration
  # -----------------------------------------------------------------------------
  # Note: Database names use the pattern: {ENV}_{LAYER} (e.g., DEV_RAW, DEV_ANL, DEV_INT)
  # Stages and file formats are created in the RAW database
  stages = {
    raw_landing = {
      database = "${local.env_prefix[lower(var.environment)]}_RAW"
      schema   = "PUBLIC" # Using PUBLIC schema in RAW database
      comment  = "Landing stage for raw data files"
    }
  }

  file_formats = {
    csv_standard = {
      database            = "${local.env_prefix[lower(var.environment)]}_RAW"
      schema              = "PUBLIC"
      format_type         = "CSV"
      compression         = "AUTO"
      field_delimiter     = ","
      skip_header         = 1
      null_if             = ["NULL", "null", ""]
      empty_field_as_null = true
      comment             = "Standard CSV format"
    }
    json_standard = {
      database            = "${local.env_prefix[lower(var.environment)]}_RAW"
      schema              = "PUBLIC"
      format_type         = "JSON"
      compression         = "AUTO"
      field_delimiter     = ""
      skip_header         = 0
      null_if             = []
      empty_field_as_null = false
      comment             = "Standard JSON format"
    }
  }

}

# =============================================================================
# SERVICE USER FOR DATA INGESTION
# =============================================================================

# Create X-SMALL warehouse for the service user
resource "snowflake_warehouse" "ingest_warehouse" {
  name              = "${upper(var.project_name)}_${upper(var.environment)}_INGEST_WH"
  warehouse_size    = "X-SMALL"
  auto_suspend      = 60
  auto_resume       = true
  min_cluster_count = 1
  max_cluster_count = 1

  comment = "Ingest warehouse for ${var.project_name} ${var.environment}"
}

# Service user for data ingestion
resource "snowflake_user" "ingest_service" {
  name = "${upper(var.project_name)}_${upper(var.environment)}_INGEST_SVC"

  # Default role for ingestion (access to RAW layer only)
  default_role = module.snowflake_account_objects.data_access_roles["INGEST"].name

  # Default warehouse for the service user
  default_warehouse = snowflake_warehouse.ingest_warehouse.name

  comment = "Service user for data ingestion - TYPE must be set to SERVICE via ALTER USER"

  # After creation, run: ALTER USER <name> SET TYPE = 'SERVICE';
  # Then configure RSA key-pair for authentication
}

# Grant INGEST role to the service user
resource "snowflake_grant_account_role" "ingest_role_to_service_user" {
  role_name = module.snowflake_account_objects.data_access_roles["INGEST"].name
  user_name = snowflake_user.ingest_service.name

  depends_on = [
    module.snowflake_account_objects,
    snowflake_user.ingest_service
  ]
}

# Grant warehouse usage to the INGEST role
resource "snowflake_grant_privileges_to_account_role" "warehouse_usage_to_ingest_role" {
  account_role_name = module.snowflake_account_objects.data_access_roles["INGEST"].name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.ingest_warehouse.name
  }

  depends_on = [
    module.snowflake_account_objects,
    snowflake_warehouse.ingest_warehouse
  ]
}

# =============================================================================
# PAT TOKEN FOR SERVICE USER
# =============================================================================

# Create Personal Access Token for the service user
resource "snowflake_user_programmatic_access_token" "ingest_service_pat" {
  name    = "${upper(var.project_name)}_${upper(var.environment)}_INGEST_PAT"
  user    = snowflake_user.ingest_service.name
  comment = "PAT token for data ingestion service"

  # Token expiry and lifecycle
  days_to_expiry                   = 90
  disabled                         = false
  expire_rotated_token_after_hours = 24

  # Security: Restrict token to INGEST role only
  role_restriction = module.snowflake_account_objects.data_access_roles["INGEST"].name

  # Allow brief network policy bypass during token rotation
  mins_to_bypass_network_policy_requirement = 10

  depends_on = [
    snowflake_user.ingest_service,
    snowflake_grant_account_role.ingest_role_to_service_user,
    module.snowflake_account_objects
  ]
}
