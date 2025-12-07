# Terraform Snowflake Account Objects Module

A comprehensive Terraform module for managing Snowflake account infrastructure with feature flags, auto-tagging, RBAC, and 3-layer data architecture. This module provides a single, configurable solution that scales from minimal deployments to enterprise-grade implementations.

## 🎯 **Features**

- 🏷️ **Auto-Tagging System**: Governance, operational, and technical tag automation
- 👥 **RBAC Hierarchy**: Simplified role inheritance (READER → WRITER → ADMIN → SYSADMIN)
- 🏗️ **3-Layer Architecture**: RAW → PREPARE → ANALYSIS data layers
- 🎛️ **Feature Flags**: Enable only what you need with granular control
- 🔒 **Security First**: No hardcoded passwords, key-pair authentication support
- 🌐 **Multi-Environment**: Support for dev, staging, and prod environments
- 📊 **Rich Outputs**: SQL commands and testing guidance included

## 🚀 **Quick Start**

### Basic Usage

```hcl
module "snowflake_account" {
  source = "augustorosa/account-objects/snowflake"
  version = "~> 1.0"

  # Project Configuration
  project_name = "analytics"
  environment  = "dev"  # dev, staging, or prod
  
  # Feature Flags - Enable what you need
  enable_rbac      = true   # Basic RBAC roles
  enable_tagging   = true   # Auto-tagging system
  enable_databases = false  # 3-layer databases
  enable_warehouses = false # Compute warehouses
}
```

### Full-Featured Deployment

```hcl
module "snowflake_account" {
  source = "augustorosa/account-objects/snowflake"
  version = "~> 1.0"

  # Project Configuration
  project_name = "dataplatform"
  environment  = "prod"
  
  # Enable All Features
  enable_rbac             = true
  enable_tagging          = true
  enable_databases        = true
  enable_warehouses       = true
  enable_data_loading     = true
  enable_resource_monitors = true
  
  # Database Configuration
  databases = {
    analytics = {
      comment = "Analytics database with 3-layer architecture"
      enable_3_layer_architecture = true
    }
    ml = {
      comment = "Machine learning database"
      enable_3_layer_architecture = true
    }
  }
  
  # Warehouse Configuration
  warehouses = {
    etl = {
      size         = "SMALL"
      auto_suspend = 60
      comment      = "ETL processing warehouse"
    }
    analytics = {
      size         = "MEDIUM" 
      auto_suspend = 300
      comment      = "Analytics queries warehouse"
    }
  }
}
```

## 🔐 **Provider Configuration**

Configure the Snowflake provider with your authentication method. **Never hardcode credentials**.

### Option 1: Environment Variables (Recommended)

```bash
# Set these in your environment or CI/CD secrets
export SNOWFLAKE_ORGANIZATION_NAME="MYORG"
export SNOWFLAKE_ACCOUNT_NAME="MYACCOUNT"
export SNOWFLAKE_USER="terraform_user"
export SNOWFLAKE_PASSWORD="your_secure_password_or_pat_token"
export SNOWFLAKE_ROLE="ACCOUNTADMIN"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
```

```hcl
# Terraform automatically picks up environment variables
provider "snowflake" {
  # No credentials needed - uses environment variables
}

module "snowflake_account" {
  source = "augustorosa/account-objects/snowflake"
  
  project_name = "myproject"
  environment  = "dev"
}
```

### Option 2: Variables (for Terraform Cloud/Enterprise)

```hcl
# variables.tf
variable "snowflake_user" {
  type      = string
  sensitive = true
}

variable "snowflake_password" {
  type      = string
  sensitive = true
}

# main.tf
provider "snowflake" {
  organization_name = "MYORG"
  account_name      = "MYACCOUNT"
  user              = var.snowflake_user
  password          = var.snowflake_password
  role              = "ACCOUNTADMIN"
  warehouse         = "COMPUTE_WH"
}
```

### Option 3: PAT Token Authentication

```hcl
provider "snowflake" {
  organization_name = "MYORG"
  account_name      = "MYACCOUNT"
  user              = "TERRAFORM_SVC"
  password          = var.pat_token  # PAT token acts as password
  role              = "ACCOUNTADMIN"
  warehouse         = "COMPUTE_WH"
}
```

See [Security & Authentication](#-security--authentication) for detailed PAT and RSA key-pair setup.

## 📋 **Requirements**

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_snowflake"></a> [snowflake](#requirement\_snowflake) | ~> 2.11.0 |

**Note**: Version 2.11.0+ required for Personal Access Tokens (PAT). Use ~> 2.0 if only using RSA key-pair authentication.

## 🔧 **Providers**

| Name | Version |
|------|---------|
| <a name="provider_snowflake"></a> [snowflake](#provider\_snowflake) | ~> 2.11.0 |

## 📦 **Resources**

This module creates the following Snowflake resources:

- **Roles**: Functional roles (READER, WRITER, ADMIN) and data access roles
- **Databases**: With optional 3-layer architecture (RAW, PREPARE, ANALYSIS)
- **Schemas**: Layer-specific schemas with proper access controls
- **Tags**: Governance, operational, and technical tags
- **Warehouses**: Configurable compute resources
- **Stages & File Formats**: Data loading infrastructure
- **Resource Monitors**: Cost control and alerting

## 🎛️ **Feature Flags**

| Feature Flag | Description | Default |
|-------------|-------------|---------|
| `enable_rbac` | Create RBAC roles and grants | `true` |
| `enable_tagging` | Create tagging infrastructure | `true` |
| `enable_databases` | Create databases with 3-layer architecture | `true` |
| `enable_warehouses` | Create and manage warehouses | `false` |
| `enable_data_loading` | Create stages, file formats, pipes | `false` |
| `enable_resource_monitors` | Create resource monitors for cost control | `false` |
| `enable_auto_classification` | Enable automatic sensitive data classification (Enterprise) | `false` |
| `enable_key_pair_auth` | Enable RSA key-pair authentication for service users | `false` |
| `enable_pat_tokens` | Enable Personal Access Token (PAT) creation | `false` |
| `enable_authentication_policies` | Enable authentication policies for enhanced security | `false` |
| `enable_external_oauth` | Enable external OAuth integrations for workload identity | `false` |
| `enable_central_settings_db` | Enable central database for network, governance, security | `true` |
| `auto_apply_tags` | Automatically apply governance and technical tags to all resources | `true` |
| `enable_network_policies` | Create network policies for IP-based access control | `false` |

## 📝 **Inputs**

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project (used in resource naming) | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_enable_rbac"></a> [enable\_rbac](#input\_enable\_rbac) | Enable RBAC (roles and grants) creation | `bool` | `true` | no |
| <a name="input_enable_tagging"></a> [enable\_tagging](#input\_enable\_tagging) | Enable tagging infrastructure | `bool` | `true` | no |
| <a name="input_enable_databases"></a> [enable\_databases](#input\_enable\_databases) | Enable database creation with 3-layer architecture | `bool` | `true` | no |
| <a name="input_enable_warehouses"></a> [enable\_warehouses](#input\_enable\_warehouses) | Enable warehouse creation and management | `bool` | `false` | no |
| <a name="input_enable_data_loading"></a> [enable\_data\_loading](#input\_enable\_data\_loading) | Enable data loading infrastructure | `bool` | `false` | no |
| <a name="input_enable_resource_monitors"></a> [enable\_resource\_monitors](#input\_enable\_resource\_monitors) | Enable resource monitors for cost control | `bool` | `false` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | Database configurations | `map(object)` | `{}` | no |
| <a name="input_warehouses"></a> [warehouses](#input\_warehouses) | Warehouse configurations | `map(object)` | `{}` | no |

## 📤 **Outputs**

| Name | Description |
|------|-------------|
| <a name="output_all_role_names"></a> [all\_role\_names](#output\_all\_role\_names) | List of all created role names |
| <a name="output_database_names"></a> [database\_names](#output\_database\_names) | List of created database names |
| <a name="output_warehouse_names"></a> [warehouse\_names](#output\_warehouse\_names) | List of created warehouse names |
| <a name="output_configuration_summary"></a> [configuration\_summary](#output\_configuration\_summary) | Summary of module configuration and resources created |
| <a name="output_sql_commands"></a> [sql\_commands](#output\_sql\_commands) | Useful SQL commands for testing and management |

## 🏗️ **Architecture**

### RBAC Hierarchy

```
SYSADMIN
    ↑
  ADMIN (inherits WRITER)
    ↑
  WRITER (inherits READER)  
    ↑
  READER
```

**Data Access Roles** (granted to ADMIN):
- `ALL_DATA_ROLE`: Access to all layers
- `ANALYSIS_ONLY_ROLE`: Business users (ANALYSIS layer only)
- `INGEST_ONLY_ROLE`: ETL tools (RAW layer only)

### 3-Layer Data Architecture

```
RAW → PREPARE → ANALYSIS
```

- **RAW**: Landing zone for source data (unmanaged access)
- **PREPARE**: Data transformation layer (managed access)
- **ANALYSIS**: Business-ready analytics layer (managed access)

### Central Settings Database

The module creates a central database named `{PROJECT_NAME}` containing:

| Schema | Purpose |
|--------|---------|
| `NETWORK` | Network rules and policies |
| `GOVERNANCE` | Governance configurations |
| `SECURITY` | Security policies and configurations |
| `AUDIT` | Audit logs and compliance tracking |
| `TAGS` | Tag definitions (optional, migrated from legacy) |

### Auto-Tagging System

When `auto_apply_tags = true` (default), the module automatically applies tags to all created resources:

| Resource Type | Tags Applied |
|--------------|--------------|
| Databases | `environment`, `project`, `terraform_managed`, `module_version` |
| Schemas | `environment`, `project`, `data_classification` (based on layer) |
| Warehouses | `environment`, `project`, `terraform_managed` |
| Roles | `environment`, `project`, `terraform_managed` |
| Service Users | `environment`, `project`, `terraform_managed` |
| Central Settings DB | `environment`, `project`, `terraform_managed`, `data_classification=RESTRICTED` |

**Tag Categories:**

**Governance Tags**: `ENVIRONMENT`, `PROJECT`, `OWNER`, `COST_CENTER`, `DATA_CLASSIFICATION`

**Operational Tags**: `CREATED_BY`, `CREATED_DATE`, `LAST_MODIFIED_BY`, `LAST_MODIFIED_DATE`

**Technical Tags**: `VERSION`, `TERRAFORM_MANAGED`, `MODULE_VERSION`

**Data Classification by Schema Layer:**
- `RAW` → `INTERNAL`
- `PREPARE` → `INTERNAL`  
- `ANALYSIS` → `CONFIDENTIAL`
- Central Settings → `RESTRICTED`

## 📚 **Examples**

| Example | Description | Use Case |
|---------|-------------|----------|
| [`basic/`](./examples/basic/) | Minimal setup with essential features | Getting started, proof of concept |
| [`comprehensive/`](./examples/comprehensive/) | Full-featured deployment | Production environments |
| [`feature-flags/`](./examples/feature-flags/) | Demonstrates all available features | Feature evaluation, testing |
| [`security-focused/`](./examples/security-focused/) | **NEW** Provider 2.7.0 security features | Enterprise security, compliance |

## 🔒 **Security & Authentication**

### Best Practices

1. **Authentication**: Configure Snowflake provider at the calling level
2. **No Hardcoded Passwords**: All sensitive values via variables
3. **Key-Pair Auth**: Recommended for production environments
4. **Least Privilege**: RBAC hierarchy enforces proper access control
5. **Network Policies**: IP restrictions and access control

### Service User Authentication Methods

The module supports two authentication methods for service users (automated systems, APIs, CI/CD pipelines):

#### 1. Personal Access Tokens (PAT) - **RECOMMENDED** ✅

**Pros**: Easy to manage, automatic rotation, role restrictions, no external key generation
**Cons**: Requires Snowflake provider v2.11.0+

**Setup**:

```hcl
module "snowflake_account" {
  source = "augustorosa/account-objects/snowflake"
  
  # Enable PAT tokens
  enable_pat_tokens = true
  
  # Create PAT tokens for service users
  pat_tokens = {
    "INGEST_SERVICE_PAT" = {
      user_name        = "MYPROJECT_DEV_INGEST_SVC"  # Service user created elsewhere
      comment          = "PAT token for data ingestion service"
      days_to_expiry   = 90                          # Token expires in 90 days
      disabled         = false
      
      # Security: Restrict token to specific roles
      role_restriction = [
        "MYPROJECT_DEV_INGEST_RL"
      ]
      
      # Allow brief network policy bypass during token rotation
      mins_to_bypass_network_policy_requirement = 10
      
      # Old tokens expire 24 hours after rotation
      expire_rotated_token_after_hours = 24
    }
  }
}

# Access the token secret (sensitive output)
output "pat_token" {
  value     = module.snowflake_account.pat_tokens["INGEST_SERVICE_PAT"].token
  sensitive = true
}
```

**Usage in CI/CD**:

```bash
# Export as environment variable
export SNOWFLAKE_PASSWORD="<pat_token_from_output>"

# Or use in GitHub Actions secrets
SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PAT_TOKEN }}
```

**Token Rotation**:
```bash
# Terraform automatically rotates on apply
terraform apply  # Creates new token, old expires after 24hrs
```

#### 2. RSA Key-Pair Authentication

**Pros**: No expiry, industry standard, more secure than passwords
**Cons**: Requires external key generation, more complex setup

**Step 1 - Generate RSA Key Pair**:

```bash
# Generate 2048-bit RSA private key
openssl genrsa -out snowflake_private_key.pem 2048

# Generate public key from private key
openssl rsa -in snowflake_private_key.pem -pubout -out snowflake_public_key.pem

# Optional: Encrypt private key with passphrase
openssl genrsa -aes256 -out snowflake_private_key_encrypted.pem 2048

# Remove headers/footers and newlines for Terraform
grep -v "BEGIN PUBLIC KEY" snowflake_public_key.pem | \
  grep -v "END PUBLIC KEY" | \
  tr -d '\n' > snowflake_public_key_base64.txt
```

**Step 2 - Configure in Terraform**:

```hcl
module "snowflake_account" {
  source = "augustorosa/account-objects/snowflake"
  
  # Enable RSA key-pair authentication
  enable_key_pair_auth = true
  
  # Create service users with RSA keys
  service_users = {
    "MYPROJECT_API_SVC" = {
      comment           = "API service user with RSA key-pair auth"
      default_role      = "MYPROJECT_DEV_INGEST_RL"
      default_warehouse = "COMPUTE_WH"
      email             = "api-service@example.com"
      
      # Primary RSA public key (from Step 1)
      rsa_public_key = file("snowflake_public_key_base64.txt")
      
      # Optional: Secondary key for rotation
      rsa_public_key_2 = null
      
      # Optional: Account expiry
      days_to_expiry = 365
    }
  }
}
```

**Step 3 - Use Private Key in Applications**:

```python
# Python Snowflake Connector
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# Load private key
with open("snowflake_private_key.pem", "rb") as key_file:
    p_key = serialization.load_pem_private_key(
        key_file.read(),
        password=None,  # or passphrase if encrypted
        backend=default_backend()
    )

# Connect to Snowflake
conn = snowflake.connector.connect(
    user='MYPROJECT_API_SVC',
    account='MYORG-MYACCOUNT',
    private_key=p_key,
    warehouse='COMPUTE_WH',
    database='DEV_RAW',
    schema='PUBLIC'
)
```

**Key Rotation**:

```hcl
# Set secondary key first
service_users = {
  "MYPROJECT_API_SVC" = {
    rsa_public_key   = "OLD_KEY_BASE64"
    rsa_public_key_2 = "NEW_KEY_BASE64"  # Add new key
  }
}

# Apply and update applications to use new key
terraform apply

# Then remove old key
service_users = {
  "MYPROJECT_API_SVC" = {
    rsa_public_key   = "NEW_KEY_BASE64"  # Old key is now primary
    rsa_public_key_2 = null
  }
}
```

### Comparison

| Feature | PAT Tokens | RSA Key-Pair |
|---------|------------|--------------|
| **Setup Complexity** | ⭐ Easy | ⭐⭐⭐ Complex |
| **External Tools** | None | OpenSSL required |
| **Rotation** | Automatic | Manual |
| **Expiry** | Yes (configurable) | No |
| **Role Restrictions** | ✅ Yes | ❌ No |
| **Network Policy Bypass** | ✅ Yes | ❌ No |
| **Provider Version** | v2.11.0+ | v2.0+ |
| **Best For** | CI/CD, APIs, automation | Long-lived services |

### Security Recommendations

1. **Use PAT tokens** for most use cases (easier management, built-in security features)
2. **Restrict PAT tokens** to specific roles using `role_restriction`
3. **Rotate tokens regularly** (90 days recommended)
4. **Store secrets securely** in HashiCorp Vault, AWS Secrets Manager, or GitHub Secrets
5. **Never commit** private keys or tokens to version control
6. **Use environment variables** for CI/CD authentication
7. **Enable MFA** for human users (not service users)
8. **Monitor token usage** via Snowflake query history

## 🧪 **Testing**

The module includes comprehensive testing:

```bash
# Run the basic example
cd examples/basic
terraform init && terraform plan

# Test feature flags
cd examples/feature-flags  
terraform init && terraform plan
```

## 🎯 **Migration**

### From Sub-Modules to Single Module

If migrating from a sub-module architecture:

```hcl
# Old approach
module "foundation" { ... }
module "database" { ... }

# New approach  
module "snowflake_account" {
  enable_rbac      = true
  enable_databases = true
}
```

### From Provider v0.x to v2.x

This module is built for Snowflake provider `~> 2.0` and handles all breaking changes from v0.x.

## 🤝 **Contributing**

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

### Quick Contribution Guide

**Commit Messages**: Follow [Conventional Commits](https://www.conventionalcommits.org/) format:
- `feat(scope): add new feature`
- `fix(scope): fix bug`
- `docs(scope): update documentation`
- `refactor(scope): refactor code`

**Pull Request Description**: Include these recommended sections:
- `## Description` - Brief overview of changes
- `## Type of Change` - Bug fix, new feature, breaking change, etc.
- `## Testing` - How the changes were tested
- `## Checklist` - Confirmation of completed tasks

See [CONTRIBUTING.md](./CONTRIBUTING.md) for complete guidelines.

## 📚 **Documentation**

For detailed technical documentation, architecture guides, and requirements:
- [Architecture Documentation](./docs/ARCHITECTURE.md)
- [RBAC Architecture](./docs/RBAC_ARCHITECTURE.md)
- [Technical Requirements](./docs/TECHNICAL_REQUIREMENTS.md)
- [Security Requirements](./docs/SECURITY_REQUIREMENTS.md)
- [Implementation Status](./docs/IMPLEMENTATION_STATUS.md)
- [Provider 2.7.0 Migration Guide](./docs/PROVIDER_2.7.0_MIGRATION.md)
- [Provider 2.11.0 Updates](./docs/PROVIDER_2.11.0_UPDATES.md) ⭐ **NEW**

## 🔮 **Future Enhancements**

- [YAML Configuration Patterns](./docs/config-patterns/) - Future GitOps-style configuration approach

## 📄 **License**

This module is licensed under the MIT License. See [LICENSE](./LICENSE) for details.

## 🆘 **Support**

- 📖 **Documentation**: Comprehensive examples and guides included
- 🐛 **Issues**: Report bugs via GitHub Issues
- 💬 **Discussions**: Use GitHub Discussions for questions
- 📧 **Contact**: For enterprise support inquiries

---

**⭐ Star this repository if it helped you!** 