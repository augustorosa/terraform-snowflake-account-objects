# TODO List - Terraform Snowflake Account Objects

**Last Updated**: November 27, 2025  
**Module Version**: v0.6.0

---

## ✅ COMPLETED CRITICAL - Architecture Alignment Issues

### 1. ✅ Role Naming Pattern
**Old**: `{ENV}_{PROJECT}_{ROLE}_ROLE` (e.g., `DEV_ULONO_ADMIN_ROLE`)  
**New**: `{ENV}_{PROJECT}_{ROLE}` (e.g., `DEV_ULONO_ADMIN`)  
**Status**: ✅ Fixed - Matches ARCHITECTURE.md  
**Files**: `rbac.tf`, `variables.tf`, `outputs.tf`

### 2. ✅ Environment Naming
**Old**: `staging` → `STG`, `prod` → `PRD`  
**New**: `dev` → `DEV`, `qa` → `QA`, `prod` → `PROD`  
**Status**: ✅ Fixed - Uses QA instead of STAGING to avoid confusion with data staging concepts  
**Files**: `main.tf` (env_prefix mapping), `variables.tf`  
**Note**: "Staging" has specific meaning in data modeling (staging tables, staging layer)

### 3. ✅ Full Role Hierarchy Implemented
**Old**: 6 generic roles (READER, WRITER, ADMIN, etc.)  
**New**: 13 architecture-compliant roles organized as:
- **Administrative** (4): ADMIN, DEVELOPER, DATA_ENGINEER, WAREHOUSE_ADMIN → SYSADMIN
- **Security** (2): USER_ADMIN, ROLE_ADMIN → SECURITYADMIN
- **Analyst** (3): ANALYST, REPORTER, VIEWER → PUBLIC
- **Integration** (3): DBT_TRANSFORMER, AIRFLOW_OPERATOR, FIVETRAN_LOADER
- Plus custom roles via `custom_roles` variable

**Status**: ✅ Complete hierarchy per ARCHITECTURE.md Section 4.1  
**Files**: `rbac.tf`, `variables.tf`, `outputs.tf`

---

## ✅ COMPLETED - RBAC Architecture Implementation (v0.6.0)

**Structure**: Per-Environment (7 roles) + Cross-Environment (1 role)

**Per Environment Roles** (e.g., DEV):
- **Functional Roles** (3): `{ENV}_{PROJECT}_READER_RL`, `{ENV}_{PROJECT}_WRITER_RL`, `{ENV}_{PROJECT}_ADMIN_RL`
  - Inheritance: READER → WRITER → ADMIN
- **Data Access Roles** (4): `{ENV}_{PROJECT}_INGEST_RL`, `{ENV}_{PROJECT}_TRANSFORM_RL`, `{ENV}_{PROJECT}_ANALYSIS_RL`, `{ENV}_{PROJECT}_SCIENTIST_RL`
  - INGEST: INSERT/COPY to RAW only
  - TRANSFORM: READ RAW, WRITE INT+ANL
  - ANALYSIS: READ ANL only
  - SCIENTIST: READ RAW+INT+ANL (all read-only)

**Cross-Environment Role**:
- `{PROJECT}_ADMIN_RL` - Inherits from all env ADMIN roles, inherits to SYSADMIN

**Grants**:
- READER_RL gets ANALYSIS_RL
- WRITER_RL gets TRANSFORM_RL (inherits ANALYSIS_RL via READER)
- ADMIN_RL gets all data access roles (INGEST, TRANSFORM, ANALYSIS, SCIENTIST)

**Database Permissions**:
- INGEST_RL: USAGE + INSERT/CREATE on RAW databases
- TRANSFORM_RL: USAGE + SELECT on RAW, USAGE + ALL on INT+ANL
- ANALYSIS_RL: USAGE + SELECT on ANL databases
- SCIENTIST_RL: USAGE + SELECT on RAW+INT+ANL databases

**Status**: ✅ Fully implemented in `rbac.tf`
**Files**: `rbac.tf`, `outputs.tf`, `examples/comprehensive/README.md`

---

## ⚠️ HIGH PRIORITY

### 4. ✅ Additional Input Validations Needed
**Missing validations**:
- [x] `log_level` (OFF, ERROR, WARN, INFO, DEBUG, TRACE)
- [x] `trace_level` (OFF, ALWAYS, ON_EVENT)
- [x] `frequency` for resource monitors (MONTHLY, DAILY, WEEKLY, YEARLY, NEVER)
- [x] `format_type` for file formats (CSV, JSON, PARQUET, AVRO, ORC, XML)
- [x] IP address formats in network policies

**Status**: ✅ Complete - All validations added to `variables.tf`

---

## 📋 MEDIUM PRIORITY

### 5. Testing
- [ ] Create unit tests for each resource type
- [ ] Create integration tests
- [ ] Add Terraform native tests (`.tftest.hcl` files)

**Directory**: `tests/`

### 6. Documentation
- [ ] Add state locking documentation
- [ ] Document migration paths for breaking changes
- [ ] Add troubleshooting guide

### 7. Migration Support
- [ ] Add `moved` blocks for ANALYZE → ANALYSIS migration
- [ ] Add preconditions to critical resources
- [ ] Document upgrade path from v0.5.0 to v0.6.0

---

## 📝 LOW PRIORITY

### 8. Code Quality
- [ ] Consolidate redundant outputs (outputs.tf is 670 lines)
- [ ] Add provider alias support for multi-account deployments
- [ ] Add timeout blocks to long-running operations
- [ ] Add import blocks for existing resources

### 9. Features
- [ ] Support for sub-schema patterns (RAW/FIVETRAN, PREPARE/STANDARDIZED, etc.)
- [ ] Default warehouse types (LOAD_WH, TRANSFORM_WH, ANALYTICS_WH)
- [ ] Auto-create integration users for common tools

---

## ✅ COMPLETED (v0.6.0)

- [x] Mark PAT token outputs as sensitive
- [x] Mark service user outputs as sensitive  
- [x] Add lifecycle prevent_destroy to databases
- [x] Fix network rule database/schema fallback (created central settings DB)
- [x] Fix redundant condition in warehouse naming
- [x] Remove timestamp() from locals (was causing drift)
- [x] Add warehouse size validation
- [x] Add scaling_policy validation
- [x] Use resource references in role grants (not string names)
- [x] Implement inherit_from for custom roles
- [x] Fix hardcoded module_version
- [x] Implement tag associations for all resources
- [x] Create central settings database
- [x] Rename ANALYZE → ANALYSIS layer
- [x] Single database naming enforced
- [x] File reorganization (13 files → 10 files)
- [x] Update to provider 2.11.0
- [x] Add key-pair authentication support
- [x] Add PAT token support
- [x] Add authentication policies
- [x] Add external OAuth integration
- [x] Add network policies and rules

---

## 🤔 DECISIONS NEEDED

### Architecture Alignment
**Question**: Should v0.6.0 strictly follow ARCHITECTURE.md?

**Current Approved Deviations**:
- ✅ Warehouses end with `_WH` (not `WH_` prefix)
- ✅ Single database approach enforced

**Awaiting Decision**:
- ❓ Remove `_ROLE` suffix from role names?
- ❓ Use full environment names (`STAGING`, `PROD` not `STG`, `PRD`)?
- ❓ Implement full 13+ role hierarchy from architecture?
- ❓ Create default integration roles (DBT, Airflow, Fivetran)?

**Impact**: These changes would be **breaking changes** requiring resource recreation.

---

## 📊 Progress Tracking

| Category | Completed | Total | Progress |
|----------|-----------|-------|----------|
| Critical Issues | 6/6 | 6 | 100% ✅ |
| High Priority | 3/7 | 7 | 43% 🟡 |
| Medium Priority | 1/7 | 7 | 14% 🔴 |
| Low Priority | 0/9 | 9 | 0% 🔴 |
| **Overall** | **10/29** | **29** | **34%** |

---

## 🎯 Next Actions

1. **Get user approval** on architecture alignment decisions
2. **If approved**: Implement role naming changes
3. **If approved**: Update environment abbreviations
4. **If approved**: Create full role hierarchy
5. Add remaining input validations
6. Create comprehensive test suite
7. Document migration paths

---

**Note**: This is a consolidated TODO list. All completed items from CRITICAL_REVIEW_TODO.md have been marked as done.

