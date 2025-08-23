# Feature Flags Example: Comprehensive Snowflake Account Objects

This example demonstrates the power and flexibility of the **single module with feature flags** approach. You can deploy exactly what you need, from a minimal RBAC setup to a full-featured data platform.

## 🎯 **What This Example Demonstrates**

### **Three Deployment Scenarios**

1. **🚀 Full Stack** - Complete data platform with all features
2. **⚡ Minimal Stack** - Basic RBAC and tagging only  
3. **🗄️ Database Only** - RBAC, tagging, and 3-layer databases

### **Feature Flag Benefits**
- ✅ **Selective Deployment** - Enable only what you need
- ✅ **Cost Control** - Don't pay for unused resources
- ✅ **Incremental Adoption** - Start small, grow as needed
- ✅ **Testing Flexibility** - Test individual components
- ✅ **Environment Scaling** - Different configs per environment

## 📋 **Prerequisites**

1. **Snowflake Account** with ACCOUNTADMIN privileges
2. **Terraform** >= 1.5.7 installed
3. **Valid Snowflake Credentials**

## 🚀 **Quick Start**

### **1. Configure Your Deployment**
```bash
# Navigate to the feature flags example
cd examples/feature-flags

# Copy and customize the variables
cp terraform.tfvars.example terraform.tfvars
```

### **2. Choose Your Deployment Scenario**
Edit `terraform.tfvars` and set **ONE** of these to `true`:

```hcl
# Full-featured deployment (recommended for testing)
deploy_full_stack = true
deploy_minimal_stack = false
deploy_database_only = false

# OR minimal deployment
deploy_full_stack = false
deploy_minimal_stack = true
deploy_database_only = false

# OR database-focused deployment
deploy_full_stack = false
deploy_minimal_stack = false
deploy_database_only = true
```

### **3. Deploy**
```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### **4. Explore Your Infrastructure**
```bash
# See what was deployed
terraform output deployment_summary

# Get testing commands
terraform output testing_commands

# Get next steps
terraform output next_steps
```

## 🏗️ **Deployment Scenarios Explained**

### **🚀 Full Stack Deployment**
**When to use**: Testing all features, production-ready setup, comprehensive demo

**What it creates**:
- ✅ **Complete RBAC** with custom roles (DATA_SCIENTIST, ML_ENGINEER, etc.)
- ✅ **Enhanced Tagging** with governance, operational, and technical tags
- ✅ **3 Databases**: Analytics (3-layer), Data Warehouse (star schema), ML Platform
- ✅ **4 Warehouses**: ETL, Analytics, ML (with query acceleration), Development
- ✅ **Data Loading**: Multiple stages and file formats (CSV, JSON, Parquet, TSV, Pipe-delimited)
- ✅ **Resource Monitors** with email notifications
- ✅ **Cortex AI** features (if enabled)

**Resource Count**: ~50+ resources

```hcl
# terraform.tfvars
deploy_full_stack = true
enable_cortex_ai = false  # Set to true if you have the right Snowflake edition
```

### **⚡ Minimal Stack Deployment**
**When to use**: Getting started, cost-conscious, basic governance only

**What it creates**:
- ✅ **Basic RBAC**: READER, WRITER, ADMIN roles with proper inheritance
- ✅ **Basic Tagging**: Tag database and essential governance tags
- ❌ No databases, warehouses, or data loading infrastructure

**Resource Count**: ~15 resources

```hcl
# terraform.tfvars
deploy_minimal_stack = true
```

### **🗄️ Database Only Deployment**
**When to use**: Data-focused projects, testing 3-layer architecture, database development

**What it creates**:
- ✅ **Basic RBAC**: Essential roles for database access
- ✅ **Basic Tagging**: Governance and operational tags
- ✅ **Single Database**: Complete 3-layer architecture (RAW, PREPARE, ANALYZE)
- ✅ **Layer Info Views**: Metadata views for each layer
- ❌ No warehouses, data loading, or resource monitors

**Resource Count**: ~25 resources

```hcl
# terraform.tfvars
deploy_database_only = true
```

## 🔧 **Advanced Configuration**

### **Custom Project Names**
Each deployment uses a different project name to avoid conflicts:
- Full stack: `${var.project_name}` (e.g., "analytics")
- Minimal: `${var.project_name}_minimal` (e.g., "analytics_minimal")  
- Database only: `${var.project_name}_dbonly` (e.g., "analytics_dbonly")

### **S3 Integration**
Configure external S3 stages for data loading:
```hcl
# terraform.tfvars
s3_data_lake_url = "s3://your-bucket/data-lake/"
s3_streaming_url = "s3://your-bucket/streaming/"
s3_credentials   = "AWS_KEY_ID='your-key' AWS_SECRET_KEY='your-secret'"
```

### **Email Notifications**
Set up team-based notifications for resource monitors:
```hcl
# terraform.tfvars
admin_email_list = ["admin@yourcompany.com", "dba@yourcompany.com"]
etl_team_emails  = ["etl-team@yourcompany.com"]
dev_team_emails  = ["dev-team@yourcompany.com"]
```

### **Cortex AI Features**
Enable AI-powered features (requires appropriate Snowflake edition):
```hcl
# terraform.tfvars
enable_cortex_ai = true
```

## 🧪 **Testing Your Deployment**

### **Full Stack Testing**
```bash
# Get comprehensive overview
terraform output full_stack

# Test RBAC
terraform output -json full_stack | jq '.all_role_names'

# Test databases
terraform output -json full_stack | jq '.database_names'

# Test warehouses  
terraform output -json full_stack | jq '.warehouse_names'

# Get SQL commands for manual testing
terraform output -json full_stack | jq '.sql_commands'
```

### **Database Architecture Testing**
```sql
-- Test the 3-layer architecture
USE DATABASE DEV_ANALYTICS_ANALYTICS_DB;

-- Check RAW layer
USE SCHEMA RAW;
SELECT * FROM _LAYER_INFO;

-- Check PREPARE layer  
USE SCHEMA PREPARE;
SELECT * FROM _LAYER_INFO;

-- Check ANALYZE layer
USE SCHEMA ANALYZE;
SELECT * FROM _LAYER_INFO;
```

### **RBAC Testing**
```sql
-- Test role hierarchy
USE ROLE DEV_ANALYTICS_READER_ROLE;
-- Should have read access

USE ROLE DEV_ANALYTICS_WRITER_ROLE;
-- Should inherit READER + have write access

USE ROLE DEV_ANALYTICS_ADMIN_ROLE;
-- Should inherit WRITER + READER + have admin access

-- Check custom roles (full stack only)
USE ROLE DEV_ANALYTICS_DATA_SCIENTIST_ROLE;
USE ROLE DEV_ANALYTICS_ML_ENGINEER_ROLE;
```

## 📊 **Feature Comparison**

| Feature | Minimal | Database Only | Full Stack |
|---------|---------|---------------|------------|
| **RBAC** | ✅ Basic | ✅ Basic | ✅ Enhanced |
| **Tagging** | ✅ Basic | ✅ Basic | ✅ Enhanced |
| **Databases** | ❌ | ✅ Single | ✅ Multiple |
| **3-Layer Architecture** | ❌ | ✅ | ✅ |
| **Warehouses** | ❌ | ❌ | ✅ Multiple |
| **Data Loading** | ❌ | ❌ | ✅ Complete |
| **Resource Monitors** | ❌ | ❌ | ✅ |
| **Cortex AI** | ❌ | ❌ | ✅ Optional |
| **Custom Roles** | ❌ | ❌ | ✅ |
| **Resource Count** | ~15 | ~25 | ~50+ |
| **Monthly Cost** | $ | $$ | $$$ |

## 🚀 **Migration Path**

Start small and grow as needed:

```
Minimal Stack
     ↓
Database Only
     ↓  
Full Stack
```

### **Step 1: Start Minimal**
```hcl
deploy_minimal_stack = true
```

### **Step 2: Add Databases**
```hcl
deploy_minimal_stack = false
deploy_database_only = true
```

### **Step 3: Go Full Featured**
```hcl
deploy_database_only = false
deploy_full_stack = true
```

## 🎛️ **Environment-Specific Configurations**

### **Development**
```hcl
project_name = "devtest"
environment = "dev"
deploy_database_only = true  # Cost-effective for development
```

### **Staging**  
```hcl
project_name = "staging"
environment = "staging"
deploy_full_stack = true
enable_cortex_ai = false  # Test without AI first
```

### **Production**
```hcl
project_name = "production"
environment = "prod"
deploy_full_stack = true
enable_cortex_ai = true
admin_email_list = ["admin@company.com", "dba@company.com", "oncall@company.com"]
```

## 🔒 **Security Best Practices**

### **Credential Management**
```bash
# Use environment variables instead of terraform.tfvars
export TF_VAR_snowflake_username="your-username"
export TF_VAR_snowflake_password="your-password"
export TF_VAR_organization_name="your-org"
export TF_VAR_snowflake_account="your-account"
```

### **Role-Based Development**
- **Developers**: Use `deploy_database_only = true`
- **Data Engineers**: Use `deploy_full_stack = true`
- **Admins**: Use all deployment types for testing

## 📈 **Monitoring and Observability**

### **Resource Monitors** (Full Stack Only)
- **Account Monitor**: 1000 credits/month, alerts at 50%, 75%, 90%
- **ETL Monitor**: 200 credits/week, alerts at 80%, 95%
- **Dev Monitor**: 50 credits/week, alerts at 70%, 85%, 95%

### **Cost Tracking**
All resources are automatically tagged for cost allocation:
```sql
-- Query costs by deployment type
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY 
WHERE TAG['deployment_type'] IN ('minimal', 'database_only', 'full_stack');
```

## 🧹 **Cleanup**

```bash
# Destroy specific deployment
terraform destroy -target=module.full_stack
terraform destroy -target=module.minimal_stack  
terraform destroy -target=module.database_only

# Or destroy everything
terraform destroy
```

## 🐛 **Troubleshooting**

### **Common Issues**

1. **Multiple Deployments Conflict**
   - Only set ONE deployment flag to `true`
   - Each uses different project names to avoid conflicts

2. **S3 Access Issues**
   - Use internal stages (`@~/`) if external S3 isn't configured
   - Check AWS credentials format

3. **Resource Monitor Notifications**
   - Verify email addresses are valid
   - Check Snowflake notification settings

4. **Cortex AI Errors**
   - Requires Business Critical or higher Snowflake edition
   - Set `enable_cortex_ai = false` if not available

## 📚 **Related Documentation**

- [Main Module README](../../README.md)
- [RBAC Architecture](../../requirements/RBAC_ARCHITECTURE.md)
- [Technical Requirements](../../requirements/TECHNICAL_REQUIREMENTS.md)
- [Contributing Guide](../../CONTRIBUTING.md)

---

This example showcases the **power of feature flags** - deploy exactly what you need, when you need it! 🎉 