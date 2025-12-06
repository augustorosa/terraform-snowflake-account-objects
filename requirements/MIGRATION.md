# Migration Guide

## 1. Overview

This guide helps you migrate to the Terraform Snowflake Account Objects module from:
- Legacy Snowflake Terraform providers (< v1.0)
- Snowflake-Labs provider to snowflakedb namespace
- Existing manual Snowflake configurations
- Other infrastructure-as-code solutions

## 2. Migration Scenarios

### 2.1 From Legacy Provider (< v1.0)

#### Key Changes
- `snowflake_role` → `snowflake_account_role`
- `snowflake_database_grant` → `snowflake_grant_privileges_to_account_role`
- Provider configuration changes
- Resource attribute changes

#### Migration Steps

1. **Update Provider Configuration**

```hcl
# OLD (Legacy)
provider "snowflake" {
  account  = "xy12345"
  region   = "us-west-2"
  username = "terraform"
  password = var.snowflake_password
  role     = "SYSADMIN"
}

# NEW (v2.3.0)
provider "snowflake" {
  organization_name = "myorg"
  account_name      = "myaccount"
  user              = "terraform"
  private_key_path  = var.private_key_path
  private_key_passphrase = var.private_key_passphrase
  role              = "SYSADMIN"
}
```

2. **Update Resource Names**

```hcl
# OLD
resource "snowflake_role" "analyst" {
  name    = "ANALYST"
  comment = "Analyst role"
}

# NEW
resource "snowflake_account_role" "analyst" {
  name    = "ANALYST"
  comment = "Analyst role"
}
```

3. **Update Grant Resources**

```hcl
# OLD
resource "snowflake_database_grant" "usage" {
  database_name = "ANALYTICS"
  privilege     = "USAGE"
  roles         = ["ANALYST"]
}

# NEW
resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  privileges        = ["USAGE"]
  role_name         = snowflake_account_role.analyst.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}
```

### 2.2 From Snowflake-Labs to snowflakedb

#### Provider Source Update

```hcl
# OLD
terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
}

# NEW
terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.3.0"
    }
  }
}
```

#### State Migration

```bash
# Replace provider in state file
terraform state replace-provider Snowflake-Labs/snowflake snowflakedb/snowflake
```

### 2.3 From Manual Configuration

#### Step 1: Inventory Existing Resources

```sql
-- List databases
SHOW DATABASES;

-- List schemas
SHOW SCHEMAS IN DATABASE <database_name>;

-- List roles
SHOW ROLES;

-- List users
SHOW USERS;

-- List warehouses
SHOW WAREHOUSES;

-- List grants
SHOW GRANTS TO ROLE <role_name>;
SHOW GRANTS ON DATABASE <database_name>;
```

#### Step 2: Generate Terraform Configuration

Use the import module to generate configurations:

```hcl
module "import_existing" {
  source = "./modules/import"
  
  scan_databases  = true
  scan_schemas    = true
  scan_roles      = true
  scan_users      = true
  scan_warehouses = true
  
  output_format = "yaml"  # or "hcl"
  output_path   = "./imported"
}
```

#### Step 3: Import Resources

```bash
# Import database
terraform import snowflake_database.main "ANALYTICS_DB"

# Import schema
terraform import snowflake_schema.raw "ANALYTICS_DB|RAW"

# Import role
terraform import snowflake_account_role.analyst "ANALYST"

# Import user
terraform import snowflake_user.john_doe "JOHN_DOE"

# Import warehouse
terraform import snowflake_warehouse.transform "TRANSFORM_WH"
```

## 3. Resource Migration Reference

### 3.1 Role Migration

| Old Resource | New Resource | Notes |
|--------------|--------------|-------|
| `snowflake_role` | `snowflake_account_role` | Account-level roles |
| `snowflake_database_role` | `snowflake_database_role` | No change |
| `snowflake_role_grants` | `snowflake_grant_privileges_to_account_role` | New grant model |

### 3.2 Grant Migration

| Old Pattern | New Pattern | Example |
|-------------|-------------|---------|
| `snowflake_database_grant` | `snowflake_grant_privileges_to_account_role` | Database privileges |
| `snowflake_schema_grant` | `snowflake_grant_privileges_to_account_role` | Schema privileges |
| `snowflake_table_grant` | `snowflake_grant_privileges_to_account_role` | Table privileges |
| `snowflake_warehouse_grant` | `snowflake_grant_privileges_to_account_role` | Warehouse privileges |

### 3.3 Example Grant Migration

```hcl
# OLD: Multiple grant resources
resource "snowflake_database_grant" "usage" {
  database_name = "ANALYTICS"
  privilege     = "USAGE"
  roles         = ["ANALYST", "DEVELOPER"]
}

resource "snowflake_database_grant" "create_schema" {
  database_name = "ANALYTICS"
  privilege     = "CREATE SCHEMA"
  roles         = ["DEVELOPER"]
}

# NEW: Single grant resource with multiple privileges
resource "snowflake_grant_privileges_to_account_role" "analyst_database" {
  privileges = ["USAGE"]
  role_name  = snowflake_account_role.analyst.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "developer_database" {
  privileges = ["USAGE", "CREATE SCHEMA"]
  role_name  = snowflake_account_role.developer.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}
```

## 4. Configuration Migration

### 4.1 From HCL Variables to YAML Configuration

**Old HCL Approach:**
```hcl
variable "roles" {
  type = map(object({
    comment = string
    users   = list(string)
  }))
  default = {
    analyst = {
      comment = "Analyst role"
      users   = ["john", "jane"]
    }
  }
}
```

**New YAML Approach:**
```yaml
# docs/config-patterns/examples/single-account/roles.yml (Documentation only)
roles:
  functional:
    analyst:
      comment: "Analyst role"
      parent_role: "PUBLIC"
      users:
        - john
        - jane
      grants:
        databases:
          - name: "{env}_{project}_db"
            schemas: ["analyze"]
            privileges: ["read"]
```

### 4.2 Environment Configuration Migration

**Old Approach:**
```hcl
# dev.tfvars
environment = "dev"
database_name = "DEV_ANALYTICS"
warehouse_size = "SMALL"

# prod.tfvars
environment = "prod"
database_name = "PROD_ANALYTICS"
warehouse_size = "LARGE"
```

**New Approach:**
```yaml
# docs/config-patterns/examples/single-account/environments.yml (Documentation only)
environments:
  dev:
    account: "main"
    defaults:
      warehouse_size: "SMALL"
      retention_days: 1
  
  prod:
    account: "main"  # or "prod-account" for multi-account
    defaults:
      warehouse_size: "LARGE"
      retention_days: 90
```

## 5. State Migration Strategies

### 5.1 Blue-Green Migration

1. **Deploy new infrastructure alongside existing**
2. **Migrate data and test**
3. **Switch over applications**
4. **Decommission old infrastructure**

```bash
# Deploy new with different names
terraform apply -var="suffix=_new"

# After validation, update names
terraform apply -var="suffix="

# Remove old resources manually
```

### 5.2 In-Place Migration

1. **Import existing resources**
2. **Update configuration to match**
3. **Plan and verify no changes**
4. **Refactor to new patterns**

```bash
# Import current state
./scripts/import_existing.sh

# Verify no changes needed
terraform plan

# Gradually refactor
terraform apply -target=module.rbac
```

## 6. Common Migration Issues

### 6.1 Grant Conflicts

**Issue**: Multiple grant resources conflict

**Solution**: Consolidate grants into single resource per role-object combination

```hcl
# Consolidate all database grants for a role
resource "snowflake_grant_privileges_to_account_role" "developer_all_database" {
  privileges = ["USAGE", "CREATE SCHEMA", "MONITOR"]
  role_name  = snowflake_account_role.developer.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.main.name
  }
}
```

### 6.2 Naming Convention Changes

**Issue**: Existing resources don't follow new naming conventions

**Solution**: Use lifecycle rules during migration

```hcl
resource "snowflake_database" "main" {
  name = "ANALYTICS"  # Old name
  
  lifecycle {
    create_before_destroy = true
  }
}

# After migration, update to new convention
# name = "${upper(var.environment)}_${upper(var.project)}_DB"
```

### 6.3 Provider Authentication

**Issue**: Password authentication to key-pair authentication

**Solution**: Gradual migration

```bash
# 1. Generate key pair
openssl genrsa -out snowflake_key.pem 2048
openssl rsa -in snowflake_key.pem -pubout -out snowflake_key.pub

# 2. Add public key to user
ALTER USER terraform SET RSA_PUBLIC_KEY='MIIBIjANBgkq...';

# 3. Test authentication
snowsql -a <account> -u terraform --private-key-path snowflake_key.pem

# 4. Update Terraform configuration
```

## 7. Migration Checklist

### 7.1 Pre-Migration

- [ ] Backup current Terraform state
- [ ] Document existing resources
- [ ] Test in development environment
- [ ] Plan rollback strategy
- [ ] Schedule maintenance window

### 7.2 Migration Steps

- [ ] Update provider version
- [ ] Update provider configuration
- [ ] Migrate resource configurations
- [ ] Update grant structures
- [ ] Import existing resources
- [ ] Validate no unwanted changes
- [ ] Apply changes incrementally

### 7.3 Post-Migration

- [ ] Verify all resources working
- [ ] Update documentation
- [ ] Update CI/CD pipelines
- [ ] Train team on new patterns
- [ ] Monitor for issues

## 8. Rollback Procedures

### 8.1 State Rollback

```bash
# List state backups
terraform state list

# Pull previous state
terraform state pull > current.tfstate
cp terraform.tfstate.backup rollback.tfstate

# Restore if needed
terraform state push rollback.tfstate
```

### 8.2 Configuration Rollback

```bash
# Git-based rollback
git checkout <previous-commit> -- .
terraform init -upgrade
terraform plan
```

## 9. Tool-Specific Migrations

### 9.1 From CloudFormation

```yaml
# CloudFormation
Resources:
  AnalyticsDatabase:
    Type: Custom::SnowflakeDatabase
    Properties:
      Name: ANALYTICS

# Terraform equivalent
resource "snowflake_database" "analytics" {
  name = "ANALYTICS"
}
```

### 9.2 From Pulumi

```python
# Pulumi
analytics_db = snowflake.Database("analytics",
    name="ANALYTICS",
    data_retention_time_in_days=7
)

# Terraform equivalent
resource "snowflake_database" "analytics" {
  name                        = "ANALYTICS"
  data_retention_time_in_days = 7
}
```

## 10. Getting Help

### 10.1 Resources

- [Snowflake Provider Documentation](https://registry.terraform.io/providers/snowflakedb/snowflake/latest/docs)
- [Migration Examples](../examples/migration/)
- [Community Forum](https://discuss.hashicorp.com/c/terraform-providers/snowflake/)

### 10.2 Common Commands

```bash
# Validate configuration
terraform validate

# Plan with detailed output
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | jq

# Import with error handling
terraform import <resource> <id> || echo "Import failed, check resource ID"

# State inspection
terraform state show <resource>
terraform state list
``` 