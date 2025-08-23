# Feature Flags Example: Comprehensive Snowflake Account Objects
# This example demonstrates how to use the single module with different feature combinations

terraform {
  required_version = ">= 1.5.7"
  
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.0"
    }
  }
}

# Configure Snowflake Provider
provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.snowflake_account
  user              = var.snowflake_username
  password          = var.snowflake_password
  role              = "ACCOUNTADMIN"
  
  preview_features_enabled = var.preview_features_enabled
}

# =============================================================================
# FULL FEATURED DEPLOYMENT
# =============================================================================

# Complete deployment with all features enabled
module "full_stack" {
  count = var.deploy_full_stack ? 1 : 0
  source = "../../"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  
  # =============================================================================
  # FEATURE FLAGS - ALL ENABLED
  # =============================================================================
  enable_rbac             = true
  enable_tagging          = true
  enable_databases        = true
  enable_warehouses       = true
  enable_data_loading     = true
  enable_resource_monitors = true
  enable_network_policies = false  # Not implemented yet
  
  # =============================================================================
  # RBAC CONFIGURATION
  # =============================================================================
  create_default_roles = true
  
  # Custom roles beyond the default READER, WRITER, ADMIN
  custom_functional_roles = {
    DATA_SCIENTIST = {
      comment = "Role for data scientists with advanced analytics access"
    }
    ML_ENGINEER = {
      comment = "Role for ML engineers with model deployment access"
    }
  }
  
  custom_data_access_roles = {
    PII_DATA = {
      comment = "Access to personally identifiable information"
    }
    FINANCIAL_DATA = {
      comment = "Access to financial datasets"
    }
  }
  
  # =============================================================================
  # TAGGING CONFIGURATION
  # =============================================================================
  create_tag_schema = true
  tag_database_suffix = "GOVERNANCE"
  
  default_tags = {
    managed_by   = "terraform"
    cost_center  = "data_platform"
    owner        = "data_team"
    project_type = "analytics"
    compliance   = "required"
  }
  
  # Enhanced tag categories
  tag_categories = {
    governance = {
      required = true
      tags     = ["environment", "project", "owner", "cost_center", "data_classification", "compliance_level"]
    }
    operational = {
      required = true
      tags     = ["created_by", "created_date", "last_modified_by", "last_modified_date", "backup_required"]
    }
    technical = {
      required = true
      tags     = ["version", "terraform_managed", "module_version", "data_source", "update_frequency"]
    }
  }
  
  # =============================================================================
  # DATABASE CONFIGURATION - MULTIPLE DATABASES
  # =============================================================================
  databases = {
    # Analytics database with full 3-layer architecture
    analytics = {
      comment = "Analytics database with RAW, PREPARE, ANALYZE layers"
      suffix  = "ANALYTICS"
      data_retention_days = 7
      
      enable_3_layer_architecture = true
      prepare_layer_managed_access = true
      prepare_layer_transient     = false
      analyze_layer_managed_access = true
      
      # Additional custom schemas
      custom_schemas = {
        SANDBOX = {
          name        = "SANDBOX"
          comment     = "Sandbox schema for experimentation"
          managed     = false
          transient   = true
        }
        ARCHIVE = {
          name        = "ARCHIVE"
          comment     = "Archive schema for historical data"
          managed     = true
          transient   = false
          data_retention_days = 90
        }
      }
      
      create_layer_info_views = true
      enable_data_loading     = true
      enable_console_output   = false
      log_level              = "OFF"
    }
    
    # Data warehouse database
    warehouse = {
      comment = "Data warehouse for business intelligence"
      suffix  = "DWH"
      data_retention_days = 30
      
      enable_3_layer_architecture = false  # Custom schema structure
      
      custom_schemas = {
        MARTS = {
          name        = "MARTS"
          comment     = "Data marts for business reporting"
          managed     = true
          transient   = false
        }
        STAGING = {
          name        = "STAGING"
          comment     = "Staging area for ETL processes"
          managed     = false
          transient   = true
        }
        DIMENSIONS = {
          name        = "DIMENSIONS"
          comment     = "Dimension tables for star schema"
          managed     = true
          transient   = false
        }
        FACTS = {
          name        = "FACTS"
          comment     = "Fact tables for star schema"
          managed     = true
          transient   = false
        }
      }
      
      create_layer_info_views = false
      enable_data_loading     = false
      enable_console_output   = true
      log_level              = "WARN"
    }
    
    # ML/AI database
    ml_platform = {
      comment = "Machine learning and AI platform database"
      suffix  = "ML"
      data_retention_days = 14
      
      enable_3_layer_architecture = true
      prepare_layer_managed_access = true
      prepare_layer_transient     = true  # Transient for ML preprocessing
      analyze_layer_managed_access = true
      
      custom_schemas = {
        MODELS = {
          name        = "MODELS"
          comment     = "ML model artifacts and metadata"
          managed     = true
          transient   = false
        }
        FEATURES = {
          name        = "FEATURES"
          comment     = "Feature store for ML pipelines"
          managed     = true
          transient   = false
        }
        EXPERIMENTS = {
          name        = "EXPERIMENTS"
          comment     = "ML experiment tracking"
          managed     = false
          transient   = true
        }
      }
      
      create_layer_info_views = true
      enable_data_loading     = true
      enable_console_output   = true
      log_level              = "INFO"
    }
  }
  
  # =============================================================================
  # WAREHOUSE CONFIGURATION
  # =============================================================================
  warehouses = {
    # ETL warehouse for data processing
    etl = {
      comment = "ETL warehouse for data processing pipelines"
      size    = "SMALL"
      auto_suspend = 60
      auto_resume  = true
      initially_suspended = true
      min_cluster_count = 1
      max_cluster_count = 3
      scaling_policy = "STANDARD"
    }
    
    # Analytics warehouse for BI workloads
    analytics = {
      comment = "Analytics warehouse for business intelligence"
      size    = "MEDIUM"
      auto_suspend = 300
      auto_resume  = true
      initially_suspended = true
      min_cluster_count = 1
      max_cluster_count = 5
      scaling_policy = "STANDARD"
    }
    
    # ML warehouse for machine learning workloads
    ml = {
      comment = "ML warehouse for machine learning workloads"
      size    = "LARGE"
      auto_suspend = 180
      auto_resume  = true
      initially_suspended = true
      min_cluster_count = 1
      max_cluster_count = 10
      scaling_policy = "ECONOMY"
      enable_query_acceleration = true
      query_acceleration_max_scale_factor = 16
    }
    
    # Development warehouse
    dev = {
      comment = "Development warehouse for testing"
      size    = "X-SMALL"
      auto_suspend = 30
      auto_resume  = true
      initially_suspended = true
      min_cluster_count = 1
      max_cluster_count = 1
      scaling_policy = "STANDARD"
    }
  }
  
  # =============================================================================
  # DATA LOADING CONFIGURATION
  # =============================================================================
  stages = {
    # Internal stages
    INTERNAL_CSV = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      comment  = "Internal stage for CSV file uploads"
      file_format = "TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1"
    }
    
    INTERNAL_JSON = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      comment  = "Internal stage for JSON file uploads"
      file_format = "TYPE = JSON"
    }
    
    # External S3 stages (examples - configure with your actual S3 details)
    S3_DATA_LAKE = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      comment  = "S3 stage for data lake ingestion"
      url      = var.s3_data_lake_url
      credentials = var.s3_credentials
      file_format = "TYPE = PARQUET"
    }
    
    S3_STREAMING = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      comment  = "S3 stage for streaming data"
      url      = var.s3_streaming_url
      credentials = var.s3_credentials
      file_format = "TYPE = JSON"
    }
  }
  
  file_formats = {
    CSV_STANDARD = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      format_type = "CSV"
      comment = "Standard CSV format with header"
      field_delimiter = ","
      skip_header = 1
      trim_space = true
      empty_field_as_null = true
      null_if = ["NULL", "null", "", "\\N"]
      encoding = "UTF8"
    }
    
    JSON_STANDARD = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      format_type = "JSON"
      comment = "Standard JSON format"
      compression = "AUTO"
    }
    
    PARQUET_OPTIMIZED = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      format_type = "PARQUET"
      comment = "Optimized Parquet format for analytics"
      compression = "SNAPPY"
    }
    
    TSV_FORMAT = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      format_type = "CSV"
      comment = "Tab-separated values format"
      field_delimiter = "\\t"
      skip_header = 1
      trim_space = true
    }
    
    PIPE_DELIMITED = {
      database = "DEV_${upper(var.project_name)}_ANALYTICS_DB"
      schema   = "RAW"
      format_type = "CSV"
      comment = "Pipe-delimited format for legacy systems"
      field_delimiter = "|"
      skip_header = 0
      trim_space = true
      empty_field_as_null = true
    }
  }
  
  # =============================================================================
  # RESOURCE MONITORS
  # =============================================================================
  resource_monitors = {
    # Account-level monitor
    account_monitor = {
      comment = "Account-level resource monitor for cost control"
      credit_quota = 1000
      frequency = "MONTHLY"
      notify_triggers = [50, 75, 90]
      notify_users = var.admin_email_list
    }
    
    # ETL-specific monitor
    etl_monitor = {
      comment = "Resource monitor for ETL workloads"
      credit_quota = 200
      frequency = "WEEKLY"
      notify_triggers = [80, 95]
      notify_users = var.etl_team_emails
    }
    
    # Development monitor (strict limits)
    dev_monitor = {
      comment = "Development environment resource monitor"
      credit_quota = 50
      frequency = "WEEKLY"
      notify_triggers = [70, 85, 95]
      notify_users = var.dev_team_emails
    }
  }
  
  # =============================================================================
  # CORTEX AI FEATURES
  # =============================================================================
  cortex_ai_features = {
    enabled = var.enable_cortex_ai
    column_descriptions = {
      enabled = var.enable_cortex_ai
      auto_generate = true
      languages = ["en"]
    }
    table_documentation = {
      enabled = var.enable_cortex_ai
      auto_summarize = true
      include_usage_patterns = true
    }
    data_classification = {
      enabled = var.enable_cortex_ai
      auto_detect_pii = true
      confidence_threshold = 0.8
    }
  }
}

# =============================================================================
# MINIMAL DEPLOYMENT EXAMPLE
# =============================================================================

# Minimal deployment with only RBAC and tagging
module "minimal_stack" {
  count = var.deploy_minimal_stack ? 1 : 0
  source = "../../"

  # Project Configuration - different project name to avoid conflicts
  project_name = "${var.project_name}_minimal"
  environment  = var.environment
  
  # =============================================================================
  # FEATURE FLAGS - MINIMAL SETUP
  # =============================================================================
  enable_rbac             = true   # Only RBAC
  enable_tagging          = true   # and tagging
  enable_databases        = false  # No databases
  enable_warehouses       = false  # No warehouses
  enable_data_loading     = false  # No data loading
  enable_resource_monitors = false  # No monitors
  enable_network_policies = false  # No network policies
  
  # Basic RBAC only
  create_default_roles = true
  
  # Basic tagging only
  create_tag_schema = true
  
  default_tags = {
    managed_by = "terraform"
    deployment_type = "minimal"
  }
}

# =============================================================================
# DATABASE-ONLY DEPLOYMENT EXAMPLE
# =============================================================================

# Database-focused deployment
module "database_only" {
  count = var.deploy_database_only ? 1 : 0
  source = "../../"

  # Project Configuration - different project name to avoid conflicts
  project_name = "${var.project_name}_dbonly"
  environment  = var.environment
  
  # =============================================================================
  # FEATURE FLAGS - DATABASE FOCUSED
  # =============================================================================
  enable_rbac             = true   # Need RBAC for database access
  enable_tagging          = true   # Need tagging for governance
  enable_databases        = true   # Main feature: databases
  enable_warehouses       = false  # No warehouses
  enable_data_loading     = false  # No data loading
  enable_resource_monitors = false  # No monitors
  enable_network_policies = false  # No network policies
  
  # Basic RBAC
  create_default_roles = true
  
  # Basic tagging
  create_tag_schema = true
  
  # Single database with 3-layer architecture
  databases = {
    main = {
      comment = "Main database with 3-layer architecture"
      suffix  = ""
      data_retention_days = 1
      
      enable_3_layer_architecture = true
      prepare_layer_managed_access = true
      analyze_layer_managed_access = true
      
      create_layer_info_views = true
    }
  }
  
  default_tags = {
    managed_by = "terraform"
    deployment_type = "database_only"
  }
} 