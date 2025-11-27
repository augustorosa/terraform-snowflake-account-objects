# Comprehensive Example: Multi-Environment Snowflake Account Objects
# This example demonstrates a realistic implementation with multiple environments
# and various configuration options.

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.0"
    }
  }
}

# Configure Snowflake Provider
provider "snowflake" {
  # Provider configuration is handled via environment variables or terraform.tfvars
  # SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_REGION
  
  # For this example, we'll configure the provider with the account format expected by the module
  organization_name = var.organization_name
  account_name      = var.snowflake_account
  user              = var.snowflake_username
  password          = var.snowflake_password
  role              = "ACCOUNTADMIN"  # Use ACCOUNTADMIN for full permissions
  
  # Enable preview features
  preview_features_enabled = var.preview_features_enabled
}

# Main Snowflake Account Objects Module
module "snowflake_account_objects" {
  source = "../../"

  # Snowflake Configuration
  snowflake_organization = var.organization_name
  snowflake_account_name = var.snowflake_account
  snowflake_username     = var.snowflake_username
  snowflake_password     = var.snowflake_password
  snowflake_role         = "ACCOUNTADMIN"  # Use ACCOUNTADMIN for full permissions
  preview_features_enabled = var.preview_features_enabled

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  
  # Module Features
  create_default_roles = true
  create_tag_schema = true
  
  # Cortex AI Features (disabled by default)
  cortex_ai_features = {
    enabled = false
    column_descriptions = {
      enabled       = false
      auto_generate = false
      languages     = ["en"]
    }
    table_documentation = {
      enabled              = false
      auto_summarize       = false
      include_usage_patterns = false
    }
    data_classification = {
      enabled          = false
      auto_detect_pii  = false
      confidence_threshold = 0.8
    }
  }
}

# Example: Create a database using the module's naming conventions
resource "snowflake_database" "analytics_db" {
  name    = "${var.project_name}_${var.environment}_analytics"
  comment = "Analytics database for ${var.project_name} ${var.environment} environment"
}

# Example: Create schemas for the 3-layer architecture
resource "snowflake_schema" "raw_schema" {
  database = snowflake_database.analytics_db.name
  name     = "RAW"
  comment  = "Raw data layer - unprocessed source data"
}

resource "snowflake_schema" "prepare_schema" {
  database = snowflake_database.analytics_db.name
  name     = "PREPARE"
  comment  = "Prepare data layer - cleaned and transformed data"
}

resource "snowflake_schema" "analysis_schema" {
  database = snowflake_database.analytics_db.name
  name     = "ANALYSIS"
  comment  = "Analyze data layer - business-ready data for reporting"
}

# Example: Create warehouses for different workloads
resource "snowflake_warehouse" "etl_warehouse" {
  name              = "${var.project_name}_${var.environment}_ETL_WH"
  warehouse_size    = "X-SMALL"
  auto_suspend      = 60
  auto_resume       = true
  min_cluster_count = 1
  max_cluster_count = 2
  
  comment = "ETL processing warehouse for ${var.project_name} ${var.environment}"
}

resource "snowflake_warehouse" "analytics_warehouse" {
  name              = "${var.project_name}_${var.environment}_ANALYTICS_WH"
  warehouse_size    = "SMALL"
  auto_suspend      = 300
  auto_resume       = true
  min_cluster_count = 1
  max_cluster_count = 3
  
  comment = "Analytics and reporting warehouse for ${var.project_name} ${var.environment}"
}

# Example: Create sample users for testing
resource "snowflake_user" "analyst_user" {
  name     = "ANALYST_${upper(var.environment)}"
  password = var.analyst_password
  comment  = "Business analyst user for ${var.environment} environment"
}

resource "snowflake_user" "engineer_user" {
  name     = "ENGINEER_${upper(var.environment)}"
  password = var.engineer_password
  comment  = "Data engineer user for ${var.environment} environment"
}

resource "snowflake_user" "admin_user" {
  name     = "ADMIN_${upper(var.environment)}"
  password = var.admin_password
  comment  = "Platform admin user for ${var.environment} environment"
}

# Example: Create sample tables for testing
resource "snowflake_table" "sample_raw_table" {
  database = snowflake_database.analytics_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "SAMPLE_RAW_DATA"
  
  column {
    name = "ID"
    type = "NUMBER"
  }
  
  column {
    name = "NAME"
    type = "VARCHAR(255)"
  }
  
  column {
    name = "CREATED_AT"
    type = "TIMESTAMP_NTZ"
  }
  
  comment = "Sample raw data table for testing"
}

resource "snowflake_table" "sample_analysis_table" {
  database = snowflake_database.analytics_db.name
  schema   = snowflake_schema.analysis_schema.name
  name     = "SAMPLE_ANALYTICS_DATA"
  
  column {
    name = "ID"
    type = "NUMBER"
  }
  
  column {
    name = "METRIC_VALUE"
    type = "FLOAT"
  }
  
  column {
    name = "REPORT_DATE"
    type = "DATE"
  }
  
  comment = "Sample analytics data table for testing"
} 