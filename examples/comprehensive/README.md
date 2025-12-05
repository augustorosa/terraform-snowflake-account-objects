# Comprehensive Example

This example demonstrates **all features** of the Snowflake Account Objects module working together.

## Features Demonstrated

| Feature | Enabled | Description |
|---------|---------|-------------|
| ✅ RBAC | Yes | Functional roles (READER, WRITER, ADMIN) + custom roles |
| ✅ Tagging | Yes | Auto-tagging system with governance, operational, technical tags |
| ✅ Databases | Yes | 3-layer architecture (RAW, PREPARE, ANALYSIS) |
| ✅ Warehouses | Yes | ETL, Analytics, and Ad-hoc warehouses |
| ✅ Data Loading | Yes | Stages and file formats for CSV/JSON |
| ✅ Resource Monitors | Yes | Monthly credit quota monitoring |
| ✅ Central Settings DB | Yes | Central database for governance |
| ⚙️ Network Policies | Optional | IP-based access control |

## Quick Start

### 1. Copy Configuration

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Configuration

Edit `terraform.tfvars` with your Snowflake credentials:

```hcl
# Required
organization_name  = "YOUR_ORG"
snowflake_account  = "YOUR_ACCOUNT"
snowflake_username = "YOUR_USERNAME"
snowflake_password = "YOUR_PASSWORD"

# Project
project_name = "analytics"
environment  = "dev"
```

### 3. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## Created Resources

### Databases (2)

| Database | Purpose |
|----------|---------|
| `DEV_ANALYTICS_ANALYTICS_DB` | Main analytics with 3-layer schemas |
| `DEV_ANALYTICS_STAGING_DB` | Staging for data validation |

### Schemas (per database)

| Schema | Purpose | Managed Access |
|--------|---------|----------------|
| `RAW` | Landing zone for source data | No |
| `PREPARE` | Cleaned and transformed data | Yes |
| `ANALYSIS` | Business-ready analytics | Yes |

### Warehouses (3)

| Warehouse | Size | Purpose |
|-----------|------|---------|
| `DEV_ANALYTICS_ETL_WH` | X-Small | ETL processing |
| `DEV_ANALYTICS_ANALYTICS_WH` | Small | BI and reporting |
| `DEV_ANALYTICS_ADHOC_WH` | X-Small | Ad-hoc queries |

### Roles

#### Functional Roles
- `DEV_ANALYTICS_READER_ROLE` - Read-only access
- `DEV_ANALYTICS_WRITER_ROLE` - Read/write access
- `DEV_ANALYTICS_ADMIN_ROLE` - Full administrative access

#### Custom Roles
- `DEV_ANALYTICS_DATA_SCIENTIST_ROLE` - Inherits from READER
- `DEV_ANALYTICS_ML_ENGINEER_ROLE` - Inherits from WRITER
- `DEV_ANALYTICS_PLATFORM_ADMIN_ROLE` - Inherits from ADMIN

#### Data Access Roles
- `DEV_ANALYTICS_RAW_READ_ROLE`
- `DEV_ANALYTICS_PREPARE_READ_ROLE`
- `DEV_ANALYTICS_ANALYSIS_READ_ROLE`
- `DEV_ANALYTICS_ANALYSIS_ONLY_ROLE`

### Central Settings Database

| Schema | Purpose |
|--------|---------|
| `NETWORK` | Network rules and policies |
| `GOVERNANCE` | Governance configurations |
| `SECURITY` | Security policies |
| `AUDIT` | Audit logs |
| `TAGS` | Tag definitions (optional) |

### Tags Applied

Tags are automatically applied to all resources:

| Tag | Applied To | Example Value |
|-----|------------|---------------|
| `environment` | All resources | `dev` |
| `project` | All resources | `analytics` |
| `data_classification` | Schemas | `INTERNAL`, `CONFIDENTIAL` |
| `cost_center` | Warehouses | `engineering` |
| `owner` | Databases | `data-team@company.com` |

## Configuration Options

### Enable Network Policies

```hcl
enable_network_policies = true

allowed_ip_ranges = [
  "10.0.0.0/8",
  "YOUR.OFFICE.IP.0/24",
]
```

### Adjust Resource Limits

```hcl
data_retention_days  = 30   # Increase retention
monthly_credit_quota = 500  # Increase credit limit
```

## Outputs

After applying, you'll see:

```bash
terraform output deployment_info
terraform output databases
terraform output warehouses
terraform output functional_roles
terraform output tag_associations_summary
```

## Clean Up

```bash
terraform destroy
```

## Security Notes

⚠️ **Never commit `terraform.tfvars` with real credentials!**

Add to `.gitignore`:
```
terraform.tfvars
*.tfstate
*.tfstate.*
```

## Next Steps

1. Review the created resources in Snowflake
2. Assign roles to users
3. Configure additional network policies if needed
4. Set up CI/CD for infrastructure changes
