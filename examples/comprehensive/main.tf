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
  required_version = ">= 1.6"

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
}

# Local variables for database naming
locals {
  env_prefix = {
    dev  = "DEV"
    qa   = "QA"
    prod = "PROD"
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
  # Pattern: {ENV}_{LAYER} (e.g., DEV_RAW, DEV_ANL, DEV_INT)
  # Schemas inside databases are for source systems or business domains
  databases = {
    raw = {
      comment                     = "Raw data layer - Source system schemas (SALESFORCE, MYSQL, etc.)"
      suffix                      = "RAW"
      data_retention_days         = var.data_retention_days
      enable_3_layer_architecture = false
      create_layer_info_views     = false
    }
    anl = {
      comment                      = "Analysis layer - Business domain schemas (CUSTOMER, PRODUCT, etc.)"
      suffix                       = "ANL"
      data_retention_days          = var.data_retention_days
      enable_3_layer_architecture  = false
      prepare_layer_managed_access = true
      prepare_layer_transient      = false
      create_layer_info_views      = false
    }
    int = {
      comment                       = "Integration layer - Analytical schemas (METRICS, REPORTS, etc.)"
      suffix                        = "INT"
      data_retention_days           = var.data_retention_days
      enable_3_layer_architecture   = false
      analysis_layer_managed_access = true
      create_layer_info_views       = false
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
