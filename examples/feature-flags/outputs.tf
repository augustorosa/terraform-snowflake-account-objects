# Feature Flags Example Outputs

# =============================================================================
# FULL STACK OUTPUTS
# =============================================================================

output "full_stack" {
  description = "Outputs from the full-featured deployment"
  value = var.deploy_full_stack ? {
    configuration_summary = module.full_stack[0].configuration_summary
    all_role_names       = module.full_stack[0].all_role_names
    database_names       = module.full_stack[0].database_names
    warehouse_names      = module.full_stack[0].warehouse_names
    sql_commands         = module.full_stack[0].sql_commands
  } : null
}

# =============================================================================
# MINIMAL STACK OUTPUTS
# =============================================================================

output "minimal_stack" {
  description = "Outputs from the minimal deployment"
  value = var.deploy_minimal_stack ? {
    configuration_summary = module.minimal_stack[0].configuration_summary
    all_role_names       = module.minimal_stack[0].all_role_names
    tag_database_name    = module.minimal_stack[0].tag_database_name
    sql_commands         = module.minimal_stack[0].sql_commands
  } : null
}

# =============================================================================
# DATABASE-ONLY OUTPUTS
# =============================================================================

output "database_only" {
  description = "Outputs from the database-only deployment"
  value = var.deploy_database_only ? {
    configuration_summary = module.database_only[0].configuration_summary
    all_role_names       = module.database_only[0].all_role_names
    database_names       = module.database_only[0].database_names
    schema_names         = module.database_only[0].schema_names
    sql_commands         = module.database_only[0].sql_commands
  } : null
}

# =============================================================================
# DEPLOYMENT SUMMARY
# =============================================================================

output "deployment_summary" {
  description = "Summary of what was deployed"
  value = {
    deployments_enabled = {
      full_stack     = var.deploy_full_stack
      minimal_stack  = var.deploy_minimal_stack
      database_only  = var.deploy_database_only
    }
    
    project_configuration = {
      project_name = var.project_name
      environment  = var.environment
    }
    
    features_demonstrated = {
      full_stack = var.deploy_full_stack ? [
        "RBAC with custom roles",
        "Enhanced tagging system", 
        "Multiple databases (Analytics, DWH, ML)",
        "Multiple warehouses (ETL, Analytics, ML, Dev)",
        "Complete data loading infrastructure",
        "Resource monitors with notifications",
        "Cortex AI features (if enabled)"
      ] : []
      
      minimal_stack = var.deploy_minimal_stack ? [
        "Basic RBAC (READER, WRITER, ADMIN)",
        "Basic tagging system"
      ] : []
      
      database_only = var.deploy_database_only ? [
        "Basic RBAC",
        "Basic tagging system",
        "Single database with 3-layer architecture"
      ] : []
    }
    
    cortex_ai_enabled = var.enable_cortex_ai
  }
}

# =============================================================================
# TESTING COMMANDS
# =============================================================================

output "testing_commands" {
  description = "Commands to test the deployed infrastructure"
  value = {
    full_stack = var.deploy_full_stack ? {
      # Test different deployment scenarios
      validate_full_deployment = "terraform output full_stack"
      
      # Test RBAC
      test_custom_roles = "terraform output -json full_stack | jq '.all_role_names'"
      
      # Test databases
      test_databases = "terraform output -json full_stack | jq '.database_names'"
      
      # Test warehouses
      test_warehouses = "terraform output -json full_stack | jq '.warehouse_names'"
      
      # Get SQL commands
      get_sql_commands = "terraform output -json full_stack | jq '.sql_commands'"
    } : null
    
    minimal_stack = var.deploy_minimal_stack ? {
      validate_minimal_deployment = "terraform output minimal_stack"
      test_basic_rbac = "terraform output -json minimal_stack | jq '.all_role_names'"
      test_tagging = "terraform output -json minimal_stack | jq '.tag_database_name'"
    } : null
    
    database_only = var.deploy_database_only ? {
      validate_database_deployment = "terraform output database_only"
      test_database_schemas = "terraform output -json database_only | jq '.schema_names'"
      test_3_layer_architecture = "terraform output -json database_only | jq '.sql_commands.database_commands'"
    } : null
  }
}

# =============================================================================
# NEXT STEPS
# =============================================================================

output "next_steps" {
  description = "Recommended next steps based on what was deployed"
  value = {
    full_stack = var.deploy_full_stack ? [
      "1. Review the comprehensive SQL commands to test all features",
      "2. Configure your S3 credentials for external stages",
      "3. Set up proper email notifications for resource monitors", 
      "4. Enable Cortex AI features if you have the appropriate Snowflake edition",
      "5. Create sample data to test the 3-layer architecture",
      "6. Set up dbt or other transformation tools to use the PREPARE layer",
      "7. Connect BI tools to the ANALYSIS layer"
    ] : []
    
    minimal_stack = var.deploy_minimal_stack ? [
      "1. Test the basic RBAC roles using the SQL commands",
      "2. Explore the tagging system for governance",
      "3. Consider enabling databases next with deploy_database_only = true",
      "4. Review the role hierarchy and permissions"
    ] : []
    
    database_only = var.deploy_database_only ? [
      "1. Test the 3-layer architecture with sample data",
      "2. Load data into the RAW layer",
      "3. Create transformations for the PREPARE layer",
      "4. Build analytics views in the ANALYSIS layer",
      "5. Consider adding warehouses next with enable_warehouses = true"
    ] : []
    
    general = [
      "• Use 'terraform plan' to see what will be created before applying",
      "• Use 'terraform output' to see connection details and SQL commands",
      "• Check the configuration_summary output to see what features are enabled",
      "• Review the module documentation for advanced configuration options"
    ]
  }
} 