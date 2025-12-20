# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-11-27

### 🚀 Major Features

#### Snowflake Provider Update
- **Updated Snowflake Terraform Provider**: 2.4.0 → **2.11.0** (latest stable)
- Full compatibility with latest Snowflake features and improvements

#### Central Settings Database
- **New central database** named `{PROJECT_NAME}` for account-level configurations
- Organized schemas: `NETWORK`, `GOVERNANCE`, `SECURITY`, `AUDIT`, `TAGS`
- All schemas with `lifecycle { prevent_destroy = true }` for safety
- Network rules now stored in dedicated NETWORK schema (fixes invalid PUBLIC fallback)

#### Authentication & Security Enhancements
- **Authentication Policies** (`snowflake_authentication_policy`) - MFA enforcement
- **External OAuth Integrations** (`snowflake_external_oauth_integration`) - Workload identity federation
- **Service Users** with RSA key-pair authentication (`snowflake_service_user`)
- **PAT Tokens** (`snowflake_user_programmatic_access_token`) with role restrictions
- **Network Policies** with IP-based access control

#### Auto-Tagging System
- **Automatic tag associations** for all resources
- Tags applied to: Databases, Schemas, Warehouses, Roles, Service Users
- **Data classification by layer**: RAW→INTERNAL, PREPARE→INTERNAL, ANALYSIS→CONFIDENTIAL
- New variable: `auto_apply_tags` (default: `true`)

### 🔧 Critical Fixes

#### Security
- ✅ PAT token outputs now marked as `sensitive = true`
- ✅ All databases have `lifecycle { prevent_destroy = true }`
- ✅ Network rules use central settings database (fixed invalid PUBLIC fallback)

#### Code Quality
- ✅ Removed `timestamp()` from locals (was causing plan drift on every run)
- ✅ Fixed redundant ternary in warehouse naming
- ✅ Role grants now use resource references instead of string names
- ✅ Implemented `inherit_from` for custom roles (was defined but unused)
- ✅ `module_version` now configurable variable (was hardcoded)

#### Input Validation
- ✅ Added warehouse size validation (X-SMALL through 6X-LARGE)
- ✅ Added scaling policy validation (STANDARD, ECONOMY)

### 📁 File Reorganization

Reduced from **13 .tf files** to **10 .tf files** for better maintainability:

| Action | Details |
|--------|---------|
| **MERGED** | `central_settings.tf` → `main.tf` |
| **MERGED** | `dw.tf` + `monitors.tf` → `compute.tf` |
| **MERGED** | `tags.tf` + `tag_associations.tf` → `tags.tf` |
| **RENAMED** | `db_schemas.tf` → `databases.tf` |
| **RENAMED** | `network_policies.tf` → `network.tf` |

#### Final File Structure
```
main.tf          (154 lines) - Locals + Central settings DB
rbac.tf          (126 lines) - Roles and grants  
tags.tf          (340 lines) - Tags + associations
databases.tf     (130 lines) - Databases + schemas + views
compute.tf       (53 lines)  - Warehouses + resource monitors
data_loading.tf  (61 lines)  - Stages + file formats
network.tf       (52 lines)  - Network rules + policies
security.tf      (90 lines)  - Service users, PAT, auth, OAuth
outputs.tf       (670 lines) - All outputs
variables.tf     (556 lines) - All variables
versions.tf      (9 lines)   - Provider version
```

### 📝 Naming Convention Update

- **Database layer renamed**: `ANALYZE` → `ANALYSIS` (140+ occurrences updated)
- Affected: schemas, roles, variables, documentation
- More intuitive naming for analytics layer

### 🆕 New Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `module_version` | Version of the module for tagging | `"0.6.0"` |
| `enable_central_settings_db` | Enable central database | `true` |
| `central_settings_data_retention_days` | Retention for central DB | `90` |
| `use_central_db_for_tags` | Migrate tags to central DB | `false` |
| `auto_apply_tags` | Auto-apply tags to resources | `true` |
| `enable_authentication_policies` | Enable auth policies | `false` |
| `enable_external_oauth` | Enable OAuth integrations | `false` |

### 🆕 New Outputs

- `central_settings_database` - Central DB details with all schemas
- `tag_associations_summary` - Summary of applied tags
- `authentication_policies` - Created auth policies
- `external_oauth_integrations` - Created OAuth integrations

### 📚 Documentation

- **New**: `docs/PROVIDER_2.11.0_UPDATES.md` - Migration guide
- **New**: `docs/CRITICAL_REVIEW_TODO.md` - Code review and improvements
- **New**: `examples/security-focused/` - Security-first example
- **Updated**: All documentation with ANALYSIS naming
- **Updated**: README with new features and examples table

### 🔄 Breaking Changes

#### Naming Changes (Requires Migration)
- Database layer: `ANALYZE` → `ANALYSIS`
- Role: `ANALYZE_ONLY_ROLE` → `ANALYSIS_ONLY_ROLE`
- Variable: `analyze_layer_managed_access` → `analysis_layer_managed_access`

#### Migration Steps
```sql
-- 1. Rename existing ANALYZE schemas in Snowflake
ALTER SCHEMA your_database.ANALYZE RENAME TO ANALYSIS;
```

```hcl
# 2. Update terraform.tfvars
# Change: analyze_layer_managed_access = true
# To:     analysis_layer_managed_access = true
```

---

## [0.5.0] - 2025-11-27

### Added
- Initial implementation of RSA key-pair authentication
- PAT token support for service users
- Network policies and rules
- Authentication test environment
- Automatic classification support (Enterprise Edition)

### Changed
- Documentation structure reorganization
- Config folder moved to docs/config-patterns

---

## [0.4.0] - 2025-11-27

### Added
- Feature flags system for granular control
- 3-layer data architecture (RAW, PREPARE, ANALYZE)
- RBAC with functional and data access roles
- Auto-tagging infrastructure
- Multiple example configurations

### Changed
- Modular architecture with feature toggles

---

## [0.1.0] - 2025-11-27

### Added
- Initial release of terraform-snowflake-account-objects module
- Basic RBAC implementation
- Database and schema management
- Warehouse configuration
- Tag infrastructure