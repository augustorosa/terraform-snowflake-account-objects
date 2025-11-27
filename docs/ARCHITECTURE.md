# Architecture Documentation

## 1. Overview

This document describes the architecture of the Terraform Snowflake Account Objects module, with a focus on the 3-layer data architecture pattern and modular design principles.

## 2. 3-Layer Data Architecture

### 2.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SNOWFLAKE ACCOUNT                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐             │
│  │   RAW       │     │  PREPARE    │     │  ANALYSIS    │             │
│  │   Layer     │ ──► │   Layer     │ ──► │   Layer     │             │
│  └─────────────┘     └─────────────┘     └─────────────┘             │
│                                                                         │
│  ┌─────────────────────────────────────────────────────┐              │
│  │                    WAREHOUSES                        │              │
│  ├──────────────┬──────────────┬────────────────────────┤              │
│  │ LOAD_WH      │ TRANSFORM_WH │ ANALYTICS_WH          │              │
│  │ (X-Small)    │ (Small-Med)  │ (Medium-Large)        │              │
│  └──────────────┴──────────────┴────────────────────────┘              │
│                                                                         │
│  ┌─────────────────────────────────────────────────────┐              │
│  │                      ROLES                           │              │
│  ├──────────────┬──────────────┬────────────────────────┤              │
│  │ LOADER       │ TRANSFORMER  │ ANALYST               │              │
│  │ ROLES        │ ROLES        │ ROLES                 │              │
│  └──────────────┴──────────────┴────────────────────────┘              │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Layer Definitions

#### 2.2.1 RAW Layer
**Purpose**: Landing zone for source data in its original format

**Characteristics**:
- No transformations applied
- Data stored as-is from source systems
- Minimal data quality checks
- Focus on data capture and storage

**Schema Structure**:
```sql
RAW/
├── FIVETRAN/          # Fivetran managed schemas
├── KAFKA/             # Streaming data landing
├── SALESFORCE/        # CRM data landing
├── FILES/             # File-based data landing
└── APIS/              # API data landing
```

**Access Patterns**:
- Write: Data loaders (Fivetran, Snowpipe, custom ETL)
- Read: Transformation processes only

#### 2.2.2 PREPARE Layer
**Purpose**: Data preparation, cleansing, normalization, and integration

**Characteristics**:
- Data type standardization
- Business key mapping
- Data quality improvements
- Cross-source integration
- Slowly Changing Dimensions (SCD) implementation

**Schema Structure**:
```sql
PREPARE/
├── STANDARDIZED/      # Type-converted and standardized
├── CLEANSED/          # Data quality applied
├── INTEGRATED/        # Cross-source joined data
├── HISTORY/           # Historical tracking (SCD)
└── STAGING/           # Temporary transformation tables
```

**Access Patterns**:
- Write: Transformation tools (dbt, Stored Procedures)
- Read: Analytics processes and advanced transformations

#### 2.2.3 ANALYSIS Layer
**Purpose**: Business-ready analytical models and reporting structures

**Characteristics**:
- Business logic applied
- Aggregated metrics
- Dimensional models
- Report-ready views
- Performance optimized

**Schema Structure**:
```sql
ANALYSIS/
├── DIMENSIONS/        # Dimension tables
├── FACTS/            # Fact tables
├── METRICS/          # Pre-calculated KPIs
├── REPORTS/          # Report-specific views
└── DATAMARTS/        # Department-specific marts
```

**Access Patterns**:
- Write: Analytics transformations (dbt models, SQL)
- Read: BI tools, Analysts, Data Scientists

## 3. Module Architecture

### 3.1 Module Hierarchy

```
terraform-snowflake-account-objects/
│
├── Root Module (main.tf)
│   ├── RBAC Module
│   │   ├── Roles Submodule
│   │   ├── Users Submodule
│   │   └── Grants Submodule
│   │
│   ├── Database Module
│   │   ├── Database Submodule
│   │   └── Schema Submodule (RAW/PREPARE/ANALYSIS)
│   │
│   ├── Warehouse Module
│   │   └── Warehouse Configuration
│   │
│   └── Data Loading Module
│       ├── Stages Submodule
│       ├── Pipes Submodule
│       └── Tasks Submodule
```

### 3.2 Module Interactions

```mermaid
graph LR
    A[YAML Config] --> B[Root Module]
    B --> C[RBAC Module]
    B --> D[Database Module]
    B --> E[Warehouse Module]
    B --> F[Data Loading Module]
    
    C --> G[Snowflake Provider]
    D --> G
    E --> G
    F --> G
    
    G --> H[Snowflake Account]
```

## 4. RBAC Architecture

### 4.1 Role Hierarchy

```
ACCOUNTADMIN
    │
    ├── SYSADMIN
    │   ├── ENV_PROJECT_ADMIN
    │   │   ├── ENV_PROJECT_DEVELOPER
    │   │   └── ENV_PROJECT_DATA_ENGINEER
    │   │
    │   └── ENV_PROJECT_WAREHOUSE_ADMIN
    │
    └── SECURITYADMIN
        ├── ENV_PROJECT_USER_ADMIN
        └── ENV_PROJECT_ROLE_ADMIN

PUBLIC
    ├── ENV_PROJECT_ANALYST
    ├── ENV_PROJECT_REPORTER
    └── ENV_PROJECT_VIEWER

Integration Roles:
    ├── ENV_PROJECT_DBT_TRANSFORMER
    ├── ENV_PROJECT_AIRFLOW_OPERATOR
    └── ENV_PROJECT_FIVETRAN_LOADER
```

### 4.2 Permission Model

| Role | RAW Layer | PREPARE Layer | ANALYSIS Layer | Warehouses |
|------|-----------|---------------|---------------|------------|
| LOADER | Write | - | - | LOAD_WH (Usage) |
| TRANSFORMER | Read | Read/Write | Write | TRANSFORM_WH (Usage/Operate) |
| ANALYST | - | Read | Read | ANALYTICS_WH (Usage) |
| DEVELOPER | Read | Read/Write | Read/Write | All (Usage/Operate) |
| ADMIN | All | All | All | All (All permissions) |

## 5. Database Architecture

### 5.1 Database Separation Strategy

```yaml
# Single Database Approach (Recommended for smaller deployments)
databases:
  main:
    name: "{env}_{project}_db"
    schemas:
      - raw
      - prepare
      - analyze

# Multi-Database Approach (Recommended for larger deployments)
databases:
  raw:
    name: "{env}_{project}_raw_db"
    schemas: ["landing", "archive"]
  
  prepare:
    name: "{env}_{project}_prepare_db"
    schemas: ["cleansed", "integrated", "staging"]
  
  analyze:
    name: "{env}_{project}_analyze_db"
    schemas: ["dimensions", "facts", "reports"]
```

### 5.2 Schema Design Patterns

#### 5.2.1 RAW Schemas
```sql
-- Naming: {source_system}_{extraction_method}
CREATE SCHEMA RAW.SALESFORCE_FIVETRAN;
CREATE SCHEMA RAW.MYSQL_CDC;
CREATE SCHEMA RAW.S3_BATCH;
```

#### 5.2.2 PREPARE Schemas
```sql
-- Naming: {business_domain}_{process}
CREATE SCHEMA PREPARE.CUSTOMER_INTEGRATION;
CREATE SCHEMA PREPARE.PRODUCT_STANDARDIZATION;
CREATE SCHEMA PREPARE.SALES_HISTORY;
```

#### 5.2.3 ANALYSIS Schemas
```sql
-- Naming: {business_function}_{type}
CREATE SCHEMA ANALYSIS.SALES_METRICS;
CREATE SCHEMA ANALYSIS.CUSTOMER_DIMENSIONS;
CREATE SCHEMA ANALYSIS.EXECUTIVE_REPORTS;
```

## 6. Warehouse Architecture

### 6.1 Warehouse Sizing Strategy

| Warehouse Type | Size | Use Case | Auto-Suspend |
|----------------|------|----------|--------------|
| LOAD_WH | X-Small to Small | Data ingestion, light transforms | 60 seconds |
| TRANSFORM_WH | Small to Medium | Heavy transformations, dbt runs | 300 seconds |
| ANALYTICS_WH | Medium to Large | Complex queries, BI tools | 600 seconds |
| ADMIN_WH | X-Small | Administrative tasks | 60 seconds |

### 6.2 Warehouse Configuration

```yaml
warehouses:
  load:
    size: "X-SMALL"
    auto_suspend: 60
    auto_resume: true
    initially_suspended: true
    scaling_policy: "STANDARD"
    
  transform:
    size: "SMALL"
    auto_suspend: 300
    auto_resume: true
    min_cluster_count: 1
    max_cluster_count: 3
    scaling_policy: "ECONOMY"
    
  analytics:
    size: "MEDIUM"
    auto_suspend: 600
    auto_resume: true
    min_cluster_count: 1
    max_cluster_count: 5
    scaling_policy: "STANDARD"
```

## 7. Integration Architecture

### 7.1 Data Flow Patterns

```
External Sources → Ingestion Tools → RAW → Transformation Tools → PREPARE → Analytics Tools → ANALYSIS → BI/Reporting
```

### 7.2 Tool Integration Points

#### 7.2.1 Fivetran Integration
- **Target**: RAW layer schemas
- **Permissions**: CREATE SCHEMA, CREATE TABLE, INSERT
- **Warehouse**: LOAD_WH
- **User Type**: Service account

#### 7.2.2 dbt Integration
- **Source**: RAW and PREPARE layers
- **Target**: PREPARE and ANALYSIS layers
- **Permissions**: SELECT on sources, CREATE/INSERT on targets
- **Warehouse**: TRANSFORM_WH
- **User Type**: Service account with key-pair auth

#### 7.2.3 Airflow Integration
- **Scope**: Orchestration across all layers
- **Permissions**: EXECUTE TASK, MONITOR, custom procedures
- **Warehouse**: Configurable per task
- **User Type**: Service account with key-pair auth

## 8. Security Architecture

### 8.1 Network Security
```yaml
network_policies:
  default:
    allowed_ips: ["0.0.0.0/0"]  # Restrict in production
    blocked_ips: []
    
  production:
    allowed_ips: 
      - "10.0.0.0/8"      # Internal network
      - "52.1.2.3/32"     # NAT Gateway
    blocked_ips: []
```

### 8.2 Encryption
- **Data at Rest**: Automatic Snowflake encryption
- **Data in Transit**: TLS 1.2 minimum
- **Key Management**: Snowflake-managed or customer-managed keys

## 9. Multi-Environment Architecture

### 9.1 Single Account Strategy
```
SNOWFLAKE_ACCOUNT
├── DEV_PROJECT_DB
│   ├── RAW
│   ├── PREPARE
│   └── ANALYSIS
├── STAGING_PROJECT_DB
│   ├── RAW
│   ├── PREPARE
│   └── ANALYSIS
└── PROD_PROJECT_DB
    ├── RAW
    ├── PREPARE
    └── ANALYSIS
```

### 9.2 Multi-Account Strategy
```
DEV_ACCOUNT
└── PROJECT_DB
    ├── RAW
    ├── PREPARE
    └── ANALYSIS

STAGING_ACCOUNT
└── PROJECT_DB
    ├── RAW
    ├── PREPARE
    └── ANALYSIS

PROD_ACCOUNT
└── PROJECT_DB
    ├── RAW
    ├── PREPARE
    └── ANALYSIS
```

## 10. Naming Convention Architecture

### 10.1 Resource Naming Pattern
```
{ENVIRONMENT}_{PROJECT}_{RESOURCE_TYPE}_{FUNCTION}

Examples:
- DEV_ANALYTICS_DB
- DEV_ANALYTICS_WH_TRANSFORM
- DEV_ANALYTICS_ROLE_DBT_TRANSFORMER
- DEV_ANALYTICS_USER_AIRFLOW
```

### 10.2 Tag Architecture
```yaml
tags:
  environment: ["dev", "staging", "prod"]
  project: ["analytics", "finance", "marketing"]
  owner: ["data-team", "analytics-team", "platform-team"]
  cost-center: ["1001", "1002", "1003"]
  data-classification: ["public", "internal", "confidential", "restricted"]
``` 