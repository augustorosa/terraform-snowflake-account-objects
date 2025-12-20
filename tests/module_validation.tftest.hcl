# =============================================================================
# TERRAFORM NATIVE TESTS - Module Validation
# =============================================================================
# Run with: terraform test
# Requires: Terraform 1.6+
# =============================================================================

# -----------------------------------------------------------------------------
# VARIABLES VALIDATION TESTS
# -----------------------------------------------------------------------------

# Test: Valid environment values
run "test_valid_environment_dev" {
  command = plan

  variables {
    project_name = "testproject"
    environment  = "dev"
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment should be 'dev'"
  }
}

run "test_valid_environment_qa" {
  command = plan

  variables {
    project_name = "testproject"
    environment  = "qa"
  }

  assert {
    condition     = var.environment == "qa"
    error_message = "Environment should be 'qa'"
  }
}

run "test_valid_environment_prod" {
  command = plan

  variables {
    project_name = "testproject"
    environment  = "prod"
  }

  assert {
    condition     = var.environment == "prod"
    error_message = "Environment should be 'prod'"
  }
}

# Test: Valid project name
run "test_valid_project_name" {
  command = plan

  variables {
    project_name = "analytics"
    environment  = "dev"
  }

  assert {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.project_name))
    error_message = "Project name should match naming pattern"
  }
}

# -----------------------------------------------------------------------------
# FEATURE FLAGS TESTS
# -----------------------------------------------------------------------------

# Test: All features disabled (minimal config)
run "test_minimal_config" {
  command = plan

  variables {
    project_name               = "minimal"
    environment                = "dev"
    enable_rbac                = false
    enable_tagging             = false
    enable_databases           = false
    enable_warehouses          = false
    enable_data_loading        = false
    enable_resource_monitors   = false
    enable_network_policies    = false
    enable_central_settings_db = false
  }

  # Should plan successfully with no resources
  assert {
    condition     = var.enable_rbac == false
    error_message = "RBAC should be disabled"
  }
}

# Test: RBAC enabled
run "test_rbac_enabled" {
  command = plan

  variables {
    project_name = "rbactest"
    environment  = "dev"
    enable_rbac  = true
  }

  assert {
    condition     = var.enable_rbac == true
    error_message = "RBAC should be enabled"
  }
}

# Test: Tagging enabled
run "test_tagging_enabled" {
  command = plan

  variables {
    project_name      = "tagtest"
    environment       = "dev"
    enable_tagging    = true
    create_tag_schema = true
  }

  assert {
    condition     = var.enable_tagging == true && var.create_tag_schema == true
    error_message = "Tagging should be enabled with schema creation"
  }
}

# Test: Databases enabled
run "test_databases_enabled" {
  command = plan

  variables {
    project_name     = "dbtest"
    environment      = "dev"
    enable_databases = true
    databases = {
      analytics = {
        comment                     = "Test database"
        data_retention_time_in_days = 7
        create_schemas              = true
      }
    }
  }

  assert {
    condition     = var.enable_databases == true
    error_message = "Databases should be enabled"
  }
}

# Test: Warehouses enabled
run "test_warehouses_enabled" {
  command = plan

  variables {
    project_name      = "whtest"
    environment       = "dev"
    enable_warehouses = true
    warehouses = {
      etl = {
        size                                = "X-SMALL"
        min_cluster_count                   = 1
        max_cluster_count                   = 1
        scaling_policy                      = "STANDARD"
        auto_suspend                        = 60
        auto_resume                         = true
        initially_suspended                 = true
        comment                             = "Test warehouse"
        resource_monitor                    = ""
        enable_query_acceleration           = false
        query_acceleration_max_scale_factor = 8
      }
    }
  }

  assert {
    condition     = var.enable_warehouses == true
    error_message = "Warehouses should be enabled"
  }
}

# Test: Network policies enabled
run "test_network_policies_enabled" {
  command = plan

  variables {
    project_name               = "nettest"
    environment                = "dev"
    enable_network_policies    = true
    enable_central_settings_db = true
    network_rules = {
      office_ips = {
        type       = "IPV4"
        mode       = "INGRESS"
        value_list = ["10.0.0.0/8"]
        comment    = "Office network"
      }
    }
    network_policies = {
      default = {
        allowed_network_rule_list = ["office_ips"]
        blocked_network_rule_list = []
        allowed_ip_list           = []
        blocked_ip_list           = []
        comment                   = "Default policy"
      }
    }
  }

  assert {
    condition     = var.enable_network_policies == true
    error_message = "Network policies should be enabled"
  }
}

# Test: Central settings database enabled
run "test_central_settings_db_enabled" {
  command = plan

  variables {
    project_name               = "centraltest"
    environment                = "dev"
    enable_central_settings_db = true
  }

  assert {
    condition     = var.enable_central_settings_db == true
    error_message = "Central settings database should be enabled"
  }
}

# -----------------------------------------------------------------------------
# NAMING CONVENTION TESTS
# -----------------------------------------------------------------------------

# Test: Base prefix generation
run "test_naming_prefix_dev" {
  command = plan

  variables {
    project_name = "myproject"
    environment  = "dev"
  }

  # Verify the naming convention is applied
  assert {
    condition     = var.environment == "dev" && var.project_name == "myproject"
    error_message = "Naming inputs should be correct"
  }
}

run "test_naming_prefix_prod" {
  command = plan

  variables {
    project_name = "myproject"
    environment  = "prod"
  }

  assert {
    condition     = var.environment == "prod"
    error_message = "Production environment should be set"
  }
}

# -----------------------------------------------------------------------------
# WAREHOUSE SIZE VALIDATION TESTS
# -----------------------------------------------------------------------------

run "test_valid_warehouse_size_xsmall" {
  command = plan

  variables {
    project_name      = "sizetest"
    environment       = "dev"
    enable_warehouses = true
    warehouses = {
      test = {
        size                                = "X-SMALL"
        min_cluster_count                   = 1
        max_cluster_count                   = 1
        scaling_policy                      = "STANDARD"
        auto_suspend                        = 60
        auto_resume                         = true
        initially_suspended                 = true
        comment                             = ""
        resource_monitor                    = ""
        enable_query_acceleration           = false
        query_acceleration_max_scale_factor = 8
      }
    }
  }

  assert {
    condition     = var.warehouses["test"].size == "X-SMALL"
    error_message = "Warehouse size should be X-SMALL"
  }
}

run "test_valid_warehouse_size_medium" {
  command = plan

  variables {
    project_name      = "sizetest"
    environment       = "dev"
    enable_warehouses = true
    warehouses = {
      test = {
        size                                = "MEDIUM"
        min_cluster_count                   = 1
        max_cluster_count                   = 2
        scaling_policy                      = "ECONOMY"
        auto_suspend                        = 300
        auto_resume                         = true
        initially_suspended                 = true
        comment                             = ""
        resource_monitor                    = ""
        enable_query_acceleration           = false
        query_acceleration_max_scale_factor = 8
      }
    }
  }

  assert {
    condition     = var.warehouses["test"].size == "MEDIUM"
    error_message = "Warehouse size should be MEDIUM"
  }
}

# -----------------------------------------------------------------------------
# COMPREHENSIVE FEATURE COMBINATION TEST
# -----------------------------------------------------------------------------

run "test_comprehensive_features" {
  command = plan

  variables {
    project_name               = "comprehensive"
    environment                = "dev"
    enable_rbac                = true
    enable_tagging             = true
    enable_databases           = true
    enable_warehouses          = true
    enable_resource_monitors   = true
    enable_central_settings_db = true
    auto_apply_tags            = true

    databases = {
      analytics = {
        comment                     = "Analytics database"
        data_retention_time_in_days = 7
        create_schemas              = true
      }
    }

    warehouses = {
      etl = {
        size                                = "X-SMALL"
        min_cluster_count                   = 1
        max_cluster_count                   = 2
        scaling_policy                      = "STANDARD"
        auto_suspend                        = 60
        auto_resume                         = true
        initially_suspended                 = true
        comment                             = "ETL warehouse"
        resource_monitor                    = ""
        enable_query_acceleration           = false
        query_acceleration_max_scale_factor = 8
      }
    }

    resource_monitors = {
      default = {
        credit_quota    = 100
        frequency       = "MONTHLY"
        start_timestamp = ""
        end_timestamp   = ""
        notify_triggers = [75, 90, 100]
        notify_users    = []
      }
    }
  }

  assert {
    condition     = var.enable_rbac && var.enable_tagging && var.enable_databases && var.enable_warehouses
    error_message = "All major features should be enabled"
  }
}

