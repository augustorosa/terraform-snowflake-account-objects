# Integration Requirements

## 1. Overview

This document outlines the integration requirements for popular data tools with the Terraform Snowflake Account Objects module. Each integration requires specific roles, permissions, and configurations to function properly within the 3-layer architecture.

## 2. dbt Integration Requirements

### 2.1 Purpose
dbt (data build tool) is used for transforming data within Snowflake, primarily operating between the RAW → PREPARE and PREPARE → ANALYSIS layers.

### 2.2 Service Account Requirements

```yaml
dbt_service_user:
  name: "{env}_{project}_dbt"
  type: "service"
  authentication: "key_pair"
  default_role: "{env}_{project}_dbt_transformer"
  default_warehouse: "{env}_{project}_transform_wh"
  must_change_password: false
```

### 2.3 Role Requirements

```yaml
dbt_roles:
  transformer:
    name: "{env}_{project}_dbt_transformer"
    parent_role: "SYSADMIN"
    grants:
      # Read from RAW layer
      - database: "{env}_{project}_db"
        schema: "raw"
        tables: "*"
        privileges: ["SELECT"]
        
      # Read/Write to PREPARE layer
      - database: "{env}_{project}_db"
        schema: "prepare"
        tables: "*"
        privileges: ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
        objects: ["CREATE TABLE", "CREATE VIEW"]
        
      # Write to ANALYSIS layer
      - database: "{env}_{project}_db"
        schema: "analyze"
        tables: "*"
        privileges: ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
        objects: ["CREATE TABLE", "CREATE VIEW", "CREATE FUNCTION"]
```

### 2.4 Warehouse Requirements

```yaml
dbt_warehouse:
  name: "{env}_{project}_transform_wh"
  size: "SMALL"
  auto_suspend: 300  # 5 minutes
  auto_resume: true
  scaling_policy: "STANDARD"
  min_cluster_count: 1
  max_cluster_count: 3
  statement_timeout: 3600  # 1 hour for long transforms
```

### 2.5 dbt Project Configuration

```yaml
# dbt_project.yml integration
models:
  project_name:
    raw:
      +database: "{{ env_var('DBT_DATABASE') }}"
      +schema: raw
      +materialized: view
      
    prepare:
      +database: "{{ env_var('DBT_DATABASE') }}"
      +schema: prepare
      +materialized: table
      
    analyze:
      +database: "{{ env_var('DBT_DATABASE') }}"
      +schema: analyze
      +materialized: table
      +tags: ["analytics"]

# profiles.yml
default:
  outputs:
    prod:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('DBT_USER') }}"
      private_key_path: "{{ env_var('DBT_PRIVATE_KEY_PATH') }}"
      role: "{{ env_var('DBT_ROLE') }}"
      database: "{{ env_var('DBT_DATABASE') }}"
      warehouse: "{{ env_var('DBT_WAREHOUSE') }}"
      schema: "{{ env_var('DBT_SCHEMA') }}"
      threads: 4
```

### 2.6 Required Permissions Summary

| Resource | Permission | Purpose |
|----------|------------|---------|
| Database | USAGE | Access database |
| Schema (RAW) | USAGE | Read source data |
| Schema (PREPARE) | USAGE, CREATE TABLE, CREATE VIEW | Transform data |
| Schema (ANALYSIS) | USAGE, CREATE TABLE, CREATE VIEW | Create models |
| Tables | SELECT, INSERT, UPDATE, DELETE, TRUNCATE | Full DML operations |
| Warehouse | USAGE, OPERATE | Run transformations |

## 3. Airflow Integration Requirements

### 3.1 Purpose
Apache Airflow orchestrates data pipelines across all layers, managing task dependencies and scheduling.

### 3.2 Service Account Requirements

```yaml
airflow_service_user:
  name: "{env}_{project}_airflow"
  type: "service"
  authentication: "key_pair"
  default_role: "{env}_{project}_airflow_operator"
  default_warehouse: "{env}_{project}_ops_wh"
```

### 3.3 Role Requirements

```yaml
airflow_roles:
  operator:
    name: "{env}_{project}_airflow_operator"
    parent_role: "SYSADMIN"
    grants:
      # Execute tasks
      account_level:
        - "EXECUTE TASK"
        - "EXECUTE MANAGED TASK"
        
      # Monitor all layers
      databases:
        - database: "{env}_{project}_db"
          privileges: ["USAGE", "MONITOR"]
          schemas: ["raw", "prepare", "analyze"]
          schema_privileges: ["USAGE", "MONITOR"]
          
      # Execute procedures
      procedures:
        - database: "{env}_{project}_db"
          schema: "*"
          privileges: ["USAGE"]
          
      # Manage tasks
      tasks:
        - database: "{env}_{project}_db"
          schema: "*"
          privileges: ["OPERATE", "MONITOR"]
```

### 3.4 Warehouse Requirements

```yaml
airflow_warehouse:
  name: "{env}_{project}_ops_wh"
  size: "X-SMALL"
  auto_suspend: 60
  auto_resume: true
  initially_suspended: true
  comment: "Warehouse for Airflow orchestration tasks"
```

### 3.5 Airflow Connection Configuration

```python
# Airflow connection configuration
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

snowflake_conn = {
    'conn_id': 'snowflake_default',
    'conn_type': 'snowflake',
    'host': '{organization}-{account}.snowflakecomputing.com',
    'schema': 'PREPARE',  # Default schema
    'login': '{env}_{project}_airflow',
    'private_key_content': '{{ var.value.snowflake_private_key }}',
    'role': '{env}_{project}_airflow_operator',
    'database': '{env}_{project}_db',
    'warehouse': '{env}_{project}_ops_wh',
}
```

### 3.6 Task Patterns

```python
# Example DAG pattern for 3-layer architecture
from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator

with DAG('data_pipeline', ...) as dag:
    
    # RAW layer: Check data arrival
    check_raw_data = SnowflakeOperator(
        task_id='check_raw_data',
        sql='SELECT COUNT(*) FROM raw.source_table WHERE load_date = CURRENT_DATE',
        warehouse='{env}_{project}_ops_wh'
    )
    
    # PREPARE layer: Run transformation
    transform_data = SnowflakeOperator(
        task_id='transform_data',
        sql='CALL prepare.transform_procedure()',
        warehouse='{env}_{project}_transform_wh'  # Use larger warehouse
    )
    
    # ANALYSIS layer: Update analytics
    update_analytics = SnowflakeOperator(
        task_id='update_analytics',
        sql='CALL analyze.refresh_metrics()',
        warehouse='{env}_{project}_analytics_wh'
    )
    
    check_raw_data >> transform_data >> update_analytics
```

### 3.7 Required Permissions Summary

| Resource | Permission | Purpose |
|----------|------------|---------|
| Account | EXECUTE TASK | Run Snowflake tasks |
| Database | USAGE, MONITOR | Access and monitor |
| Schema | USAGE, MONITOR | Access and monitor |
| Tasks | OPERATE, MONITOR | Manage task execution |
| Procedures | USAGE | Execute stored procedures |
| Warehouses | USAGE, OPERATE | Run queries and manage |

## 4. Fivetran Integration Requirements

### 4.1 Purpose
Fivetran loads data from various sources into the RAW layer of the Snowflake data architecture.

### 4.2 Service Account Requirements

```yaml
fivetran_service_user:
  name: "{env}_{project}_fivetran"
  type: "service"
  authentication: "password"  # Fivetran typically uses password auth
  default_role: "{env}_{project}_fivetran_loader"
  default_warehouse: "{env}_{project}_load_wh"
```

### 4.3 Role Requirements

```yaml
fivetran_roles:
  loader:
    name: "{env}_{project}_fivetran_loader"
    parent_role: "SYSADMIN"
    grants:
      # Create and manage schemas in RAW layer
      - database: "{env}_{project}_db"
        privileges: ["USAGE", "CREATE SCHEMA", "MONITOR"]
        
      # Full access to RAW schemas
      - database: "{env}_{project}_db"
        schema: "raw"
        privileges: ["USAGE", "CREATE TABLE", "CREATE STAGE"]
        tables: "*"
        table_privileges: ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
        
      # Fivetran metadata schema
      - database: "{env}_{project}_db"
        schema: "fivetran_metadata"
        privileges: ["USAGE", "CREATE TABLE", "CREATE VIEW"]
        ownership: true
```

### 4.4 Warehouse Requirements

```yaml
fivetran_warehouse:
  name: "{env}_{project}_load_wh"
  size: "X-SMALL"
  auto_suspend: 60
  auto_resume: true
  scaling_policy: "STANDARD"
  min_cluster_count: 1
  max_cluster_count: 2  # Scale for parallel loads
  comment: "Warehouse for Fivetran data loading"
```

### 4.5 Schema Structure for Fivetran

```sql
-- Fivetran creates schemas per connector
RAW/
├── SALESFORCE/           # Salesforce connector
├── GOOGLE_ADS/          # Google Ads connector
├── STRIPE/              # Stripe connector
├── MYSQL_REPLICA/       # MySQL database replica
└── FIVETRAN_METADATA/   # Fivetran system tables
```

### 4.6 Fivetran Configuration

```yaml
# Fivetran destination configuration
destination:
  type: "snowflake"
  config:
    host: "{organization}-{account}.snowflakecomputing.com"
    port: 443
    database: "{env}_{project}_db"
    auth: "PASSWORD"
    user: "{env}_{project}_fivetran"
    password: "{{ secret }}"
    role: "{env}_{project}_fivetran_loader"
    warehouse: "{env}_{project}_load_wh"
```

### 4.7 Landing Table Patterns

```sql
-- Fivetran standard table structure
CREATE TABLE raw.salesforce.account (
    -- Fivetran system columns
    _fivetran_deleted BOOLEAN,
    _fivetran_synced TIMESTAMP_TZ,
    
    -- Source columns
    id VARCHAR,
    name VARCHAR,
    created_date TIMESTAMP_TZ,
    -- ... other columns
    
    -- Best practice: Add load timestamp
    _loaded_at TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP()
);
```

### 4.8 Required Permissions Summary

| Resource | Permission | Purpose |
|----------|------------|---------|
| Database | USAGE, CREATE SCHEMA | Create connector schemas |
| Schema (RAW) | USAGE, CREATE TABLE, CREATE STAGE | Create landing tables |
| Tables | All DML operations | Load and update data |
| Warehouse | USAGE | Run load operations |
| Schema (FIVETRAN_METADATA) | OWNERSHIP | Manage sync metadata |

## 5. Integration Module Structure

### 5.1 Module Organization

```
modules/integrations/
├── dbt/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── service_user.tf
│   ├── roles.tf
│   ├── grants.tf
│   └── README.md
│
├── airflow/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── service_user.tf
│   ├── roles.tf
│   ├── grants.tf
│   ├── tasks.tf
│   └── README.md
│
└── fivetran/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── service_user.tf
    ├── roles.tf
    ├── grants.tf
    ├── schemas.tf
    └── README.md
```

### 5.2 Module Usage Example

```hcl
# Main configuration
module "snowflake_integrations" {
  source = "./modules/integrations"
  
  environment = var.environment
  project     = var.project
  
  # Enable integrations
  enable_dbt       = true
  enable_airflow   = true
  enable_fivetran  = true
  
  # Integration-specific configs
  dbt_config = {
    warehouse_size = "SMALL"
    threads        = 4
  }
  
  airflow_config = {
    task_timeout = 3600
    max_retries  = 3
  }
  
  fivetran_config = {
    connectors = ["salesforce", "google_ads", "stripe"]
  }
}
```

## 6. Security Considerations

### 6.1 Authentication Best Practices

1. **Key-Pair Authentication**:
   - Use for dbt and Airflow
   - Rotate keys every 90 days
   - Store private keys in secure vaults

2. **Password Authentication**:
   - Use only for Fivetran (if required)
   - Use strong, randomly generated passwords
   - Rotate every 60 days

3. **Network Security**:
   - Restrict access by IP for service accounts
   - Use private endpoints where possible
   - Enable MFA for human users

### 6.2 Audit and Monitoring

```sql
-- Monitor integration usage
CREATE OR REPLACE VIEW monitor.integration_usage AS
SELECT 
    user_name,
    role_name,
    warehouse_name,
    COUNT(*) as query_count,
    SUM(credits_used) as total_credits,
    DATE(start_time) as query_date
FROM snowflake.account_usage.query_history
WHERE user_name IN (
    '{env}_{project}_dbt',
    '{env}_{project}_airflow',
    '{env}_{project}_fivetran'
)
GROUP BY 1,2,3,6;
```

## 7. Cost Optimization

### 7.1 Warehouse Sizing Guidelines

| Integration | Recommended Size | When to Scale Up |
|-------------|-----------------|------------------|
| dbt | SMALL | Complex models, > 1TB data |
| Airflow | X-SMALL | Many concurrent tasks |
| Fivetran | X-SMALL | Large initial loads |

### 7.2 Auto-Suspend Recommendations

- **dbt**: 300 seconds (allows for multiple model runs)
- **Airflow**: 60 seconds (quick task execution)
- **Fivetran**: 60 seconds (frequent small loads)

## 8. Troubleshooting Common Issues

### 8.1 dbt Issues

```sql
-- Check dbt permissions
SHOW GRANTS TO ROLE {env}_{project}_dbt_transformer;
SHOW GRANTS ON SCHEMA {env}_{project}_db.prepare;
```

### 8.2 Airflow Issues

```sql
-- Check task execution
SHOW TASKS IN DATABASE {env}_{project}_db;
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE name = 'task_name';
```

### 8.3 Fivetran Issues

```sql
-- Check Fivetran schema access
SHOW SCHEMAS IN DATABASE {env}_{project}_db;
SHOW TABLES IN SCHEMA {env}_{project}_db.raw;
``` 