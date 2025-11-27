# Module Outputs
output "module_outputs" {
  description = "Outputs from the snowflake_account_objects module"
  value = {
    functional_roles     = module.snowflake_account_objects.functional_roles
    data_access_roles    = module.snowflake_account_objects.data_access_roles
    all_roles           = module.snowflake_account_objects.all_roles
    functional_role_names = module.snowflake_account_objects.functional_role_names
    data_access_role_names = module.snowflake_account_objects.data_access_role_names
    all_role_names      = module.snowflake_account_objects.all_role_names
  }
}

# Database Outputs
output "analytics_database" {
  description = "Analytics database details"
  value = {
    name    = snowflake_database.analytics_db.name
    comment = snowflake_database.analytics_db.comment
  }
}

# Schema Outputs
output "data_schemas" {
  description = "Data layer schemas"
  value = {
    raw     = {
      name    = snowflake_schema.raw_schema.name
      comment = snowflake_schema.raw_schema.comment
    }
    prepare = {
      name    = snowflake_schema.prepare_schema.name
      comment = snowflake_schema.prepare_schema.comment
    }
    analysis = {
      name    = snowflake_schema.analysis_schema.name
      comment = snowflake_schema.analysis_schema.comment
    }
  }
}

# Warehouse Outputs
output "warehouses" {
  description = "Warehouse details"
  value = {
    etl = {
      name           = snowflake_warehouse.etl_warehouse.name
      warehouse_size = snowflake_warehouse.etl_warehouse.warehouse_size
      auto_suspend   = snowflake_warehouse.etl_warehouse.auto_suspend
      comment        = snowflake_warehouse.etl_warehouse.comment
    }
    analytics = {
      name           = snowflake_warehouse.analytics_warehouse.name
      warehouse_size = snowflake_warehouse.analytics_warehouse.warehouse_size
      auto_suspend   = snowflake_warehouse.analytics_warehouse.auto_suspend
      comment        = snowflake_warehouse.analytics_warehouse.comment
    }
  }
}

# User Outputs
output "users" {
  description = "Created users"
  value = {
    analyst = {
      name    = snowflake_user.analyst_user.name
      comment = snowflake_user.analyst_user.comment
    }
    engineer = {
      name    = snowflake_user.engineer_user.name
      comment = snowflake_user.engineer_user.comment
    }
    admin = {
      name    = snowflake_user.admin_user.name
      comment = snowflake_user.admin_user.comment
    }
  }
}

# Table Outputs
output "sample_tables" {
  description = "Sample tables created for testing"
  value = {
    raw_data = {
      name    = snowflake_table.sample_raw_table.name
      schema  = snowflake_table.sample_raw_table.schema
      comment = snowflake_table.sample_raw_table.comment
    }
    analytics_data = {
      name    = snowflake_table.sample_analysis_table.name
      schema  = snowflake_table.sample_analysis_table.schema
      comment = snowflake_table.sample_analysis_table.comment
    }
  }
}

# Role Assignment Examples
output "role_usage_examples" {
  description = "Examples of how to use the created roles"
  value = {
    analyst_role = {
      role_name = module.snowflake_account_objects.functional_roles["READER"].name
      user_name = snowflake_user.analyst_user.name
      permissions = "Read-only access to ANALYSIS layer"
      sql_command = "GRANT ROLE ${module.snowflake_account_objects.functional_roles["READER"].name} TO USER ${snowflake_user.analyst_user.name};"
    }
    engineer_role = {
      role_name = module.snowflake_account_objects.functional_roles["WRITER"].name
      user_name = snowflake_user.engineer_user.name
      permissions = "Read/write access to all layers (inherits READER)"
      sql_command = "GRANT ROLE ${module.snowflake_account_objects.functional_roles["WRITER"].name} TO USER ${snowflake_user.engineer_user.name};"
    }
    admin_role = {
      role_name = module.snowflake_account_objects.functional_roles["ADMIN"].name
      user_name = snowflake_user.admin_user.name
      permissions = "Full access to everything (inherits WRITER + READER)"
      sql_command = "GRANT ROLE ${module.snowflake_account_objects.functional_roles["ADMIN"].name} TO USER ${snowflake_user.admin_user.name};"
    }
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for testing"
  value = {
    account  = var.snowflake_account
    region   = var.snowflake_region
    database = snowflake_database.analytics_db.name
    warehouse_etl = snowflake_warehouse.etl_warehouse.name
    warehouse_analytics = snowflake_warehouse.analytics_warehouse.name
  }
  sensitive = true
}

# Testing Commands
output "testing_commands" {
  description = "SQL commands to test the implementation"
  value = {
    grant_roles = [
      "GRANT ROLE ${module.snowflake_account_objects.functional_roles["READER"].name} TO USER ${snowflake_user.analyst_user.name};",
      "GRANT ROLE ${module.snowflake_account_objects.functional_roles["WRITER"].name} TO USER ${snowflake_user.engineer_user.name};",
      "GRANT ROLE ${module.snowflake_account_objects.functional_roles["ADMIN"].name} TO USER ${snowflake_user.admin_user.name};"
    ]
    test_analyst_access = "USE ROLE ${module.snowflake_account_objects.functional_roles["READER"].name}; USE DATABASE ${snowflake_database.analytics_db.name}; USE SCHEMA ${snowflake_schema.analysis_schema.name}; SELECT * FROM ${snowflake_table.sample_analysis_table.name} LIMIT 10;"
    test_engineer_access = "USE ROLE ${module.snowflake_account_objects.functional_roles["WRITER"].name}; USE DATABASE ${snowflake_database.analytics_db.name}; USE SCHEMA ${snowflake_schema.raw_schema.name}; SELECT * FROM ${snowflake_table.sample_raw_table.name} LIMIT 10;"
    test_admin_access = "USE ROLE ${module.snowflake_account_objects.functional_roles["ADMIN"].name}; USE DATABASE ${snowflake_database.analytics_db.name}; SHOW SCHEMAS;"
    check_role_hierarchy = "SHOW GRANTS TO ROLE ${module.snowflake_account_objects.functional_roles["ADMIN"].name};"
  }
} 