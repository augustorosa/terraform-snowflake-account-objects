# Comprehensive Example: Multi-Environment Snowflake Account Objects

This example demonstrates a complete, production-ready implementation of the Snowflake Account Objects module with realistic usage patterns and testing capabilities.

## 🎯 What This Example Creates

### 1. **Module Foundation**
- ✅ RBAC roles with proper inheritance (READER → WRITER → ADMIN → SYSADMIN)
- ✅ Tag schema for governance, operational, and technical tags
- ✅ Naming conventions and procedures
- ✅ Cortex AI features (disabled by default)

### 2. **Data Architecture**
- ✅ Analytics database with 3-layer architecture:
  - **RAW**: Unprocessed source data
  - **PREPARE**: Cleaned and transformed data  
  - **ANALYSIS**: Business-ready data for reporting
- ✅ Sample tables in RAW and ANALYSIS layers

### 3. **Compute Resources**
- ✅ ETL warehouse (X-SMALL, auto-suspend 60s)
- ✅ Analytics warehouse (SMALL, auto-suspend 300s)

### 4. **Users and Access Control**
- ✅ Analyst user with READER role
- ✅ Engineer user with WRITER role
- ✅ Admin user with ADMIN role
- ✅ Proper role assignments and permissions

### 5. **Testing Infrastructure**
- ✅ Sample tables for testing permissions
- ✅ SQL commands for manual role grants
- ✅ Database, schema, and warehouse creation

## 🚀 Quick Start

### Prerequisites
- Terraform >= 1.0
- Snowflake account with SYSADMIN access
- Snowflake provider configured

### 1. **Configure Variables**
```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### 2. **Initialize and Apply**
```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 3. **Test the Implementation**
```bash
# Get testing commands
terraform output testing_commands

# Get role assignment commands
terraform output role_usage_examples
```

## 📊 What Gets Created

### **Roles Created**
```
analytics_dev_READER_ROLE     # Read-only access
analytics_dev_WRITER_ROLE     # Read/write access (inherits READER)
analytics_dev_ADMIN_ROLE      # Full access (inherits WRITER)
analytics_dev_ALL_DATA_ROLE   # Access to all data layers
analytics_dev_ANALYSIS_ONLY_ROLE # Access to ANALYSIS layer only
analytics_dev_INGEST_ONLY_ROLE  # Access to RAW layer only
```

### **Database and Schemas**
```
analytics_dev_analytics (Database)
├── RAW (Schema) - Raw data layer
├── PREPARE (Schema) - Prepared data layer
└── ANALYSIS (Schema) - Analytics data layer
```

### **Warehouses**
```
analytics_dev_ETL_WH        # ETL processing
analytics_dev_ANALYTICS_WH  # Analytics and reporting
```

### **Users**
```
ANALYST_DEV   # Business analyst (READER role)
ENGINEER_DEV  # Data engineer (WRITER role)
ADMIN_DEV     # Platform admin (ADMIN role)
```

## 🧪 Testing the Implementation

### **1. Grant Roles to Users**
```sql
-- Grant roles to users (run these commands manually)
GRANT ROLE analytics_dev_READER_ROLE TO USER ANALYST_DEV;
GRANT ROLE analytics_dev_WRITER_ROLE TO USER ENGINEER_DEV;
GRANT ROLE analytics_dev_ADMIN_ROLE TO USER ADMIN_DEV;
```

### **2. Test Analyst Access (Read-Only)**
```sql
-- Connect as ANALYST_DEV
USE ROLE analytics_dev_READER_ROLE;
USE DATABASE analytics_dev_analytics;
USE SCHEMA ANALYSIS;
SELECT * FROM SAMPLE_ANALYTICS_DATA LIMIT 10;
```

### **3. Test Engineer Access (Read/Write)**
```sql
-- Connect as ENGINEER_DEV
USE ROLE analytics_dev_WRITER_ROLE;
USE DATABASE analytics_dev_analytics;
USE SCHEMA RAW;
SELECT * FROM SAMPLE_RAW_DATA LIMIT 10;
-- Should also have access to ANALYSIS layer (inherits READER)
USE SCHEMA ANALYSIS;
SELECT * FROM SAMPLE_ANALYTICS_DATA LIMIT 10;
```

### **4. Test Admin Access (Full Access)**
```sql
-- Connect as ADMIN_DEV
USE ROLE analytics_dev_ADMIN_ROLE;
USE DATABASE analytics_dev_analytics;
SHOW SCHEMAS;
-- Should have access to everything
```

### **5. Verify Role Hierarchy**
```sql
-- Check what roles inherit from ADMIN
SHOW GRANTS TO ROLE analytics_dev_ADMIN_ROLE;

-- Check what roles inherit from WRITER
SHOW GRANTS TO ROLE analytics_dev_WRITER_ROLE;
```

## 🔧 Customization Options

### **Enable Cortex AI Features**
```hcl
cortex_ai_features = {
  enabled = true
  column_descriptions = {
    enabled       = true
    auto_generate = true
    languages     = ["en", "es"]
  }
  table_documentation = {
    enabled              = true
    auto_summarize       = true
    include_usage_patterns = true
  }
  data_classification = {
    enabled          = true
    auto_detect_pii  = true
    confidence_threshold = 0.8
  }
}
```

### **Add Custom Tags**
```hcl
custom_tags = {
  cost_center = "data-platform"
  data_owner  = "data-team"
  compliance  = "internal"
  project_id  = "PRJ-001"
}
```

### **Different Environment**
```hcl
environment = "staging"  # or "prod"
project_name = "customer-analytics"
```

## 🛡️ Security Features

### **Role Inheritance**
- **READER** → **WRITER** → **ADMIN** → **SYSADMIN**
- Each role inherits permissions from the previous level
- Clear permission escalation

### **Data Layer Access**
- **READER**: Access to ANALYSIS layer only
- **WRITER**: Access to all layers (inherits READER)
- **ADMIN**: Full access to everything

### **Tag-Based Governance**
- Environment tags for resource tracking
- Project tags for cost allocation
- Team tags for ownership
- Data layer tags for classification

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

**⚠️ Warning**: This will delete all created databases, schemas, tables, warehouses, users, and roles.

## 📈 Production Considerations

### **1. Password Management**
- Use secure password management (HashiCorp Vault, AWS Secrets Manager)
- Rotate passwords regularly
- Use key-pair authentication for service accounts

### **2. Environment Separation**
- Use separate Snowflake accounts for dev/staging/prod
- Or use different databases within the same account
- Implement proper data isolation

### **3. Monitoring and Alerting**
- Set up warehouse usage monitoring
- Monitor role assignments and permissions
- Track tag compliance

### **4. Backup and Recovery**
- Implement database backup strategies
- Document recovery procedures
- Test disaster recovery scenarios

## 🔗 Related Documentation

- [Module Documentation](../../README.md)
- [RBAC Architecture](../../docs/RBAC_ARCHITECTURE.md)
- [Technical Requirements](../../docs/TECHNICAL_REQUIREMENTS.md)
- [Integration Requirements](../../docs/INTEGRATION_REQUIREMENTS.md) 