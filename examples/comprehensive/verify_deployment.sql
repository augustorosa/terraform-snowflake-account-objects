-- =============================================================================
-- TERRAFORM DEPLOYMENT VERIFICATION SCRIPT
-- =============================================================================
-- This script verifies that the Terraform module deployment was successful
-- Run this script after terraform apply to validate all resources
-- =============================================================================

-- Set context
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- =============================================================================
-- 1. DATABASE VERIFICATION
-- =============================================================================
SELECT 'DATABASE VERIFICATION' AS verification_section;

-- Query databases directly (account_usage may be delayed up to 2 hours after creation)
-- Try information_schema first (immediate), fallback note about account_usage delay
SELECT 
    'DATABASE' AS resource_type,
    catalog_name AS database_name,
    comment,
    CASE 
        WHEN catalog_name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL') THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM information_schema.databases
WHERE catalog_name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
ORDER BY catalog_name;

-- Verify database tags
SELECT 
    'DATABASE TAGS' AS resource_type,
    OBJECT_DATABASE AS database_name,
    TAG_DATABASE || '.' || TAG_SCHEMA || '.' || TAG_NAME AS tag_name,
    TAG_VALUE,
    CASE 
        WHEN TAG_VALUE IN ('DEV', 'ulono', '0.6.0', 'true') THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.tag_references
WHERE OBJECT_DATABASE IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
  AND OBJECT_SCHEMA IS NULL
  AND OBJECT_NAME IS NULL
ORDER BY OBJECT_DATABASE, TAG_NAME;

-- =============================================================================
-- 2. ROLE VERIFICATION
-- =============================================================================
SELECT 'ROLE VERIFICATION' AS verification_section;

-- Functional Roles (should end with _RL)
SELECT 
    'FUNCTIONAL_ROLE' AS role_type,
    role_name,
    comment,
    CASE 
        WHEN role_name IN ('DEV_ULONO_READER_RL', 'DEV_ULONO_WRITER_RL', 'DEV_ULONO_ADMIN_RL') 
             AND role_name LIKE '%_RL' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.roles
WHERE role_name IN ('DEV_ULONO_READER_RL', 'DEV_ULONO_WRITER_RL', 'DEV_ULONO_ADMIN_RL')
ORDER BY role_name;

-- Data Access Roles
SELECT 
    'DATA_ACCESS_ROLE' AS role_type,
    role_name,
    comment,
    CASE 
        WHEN role_name IN ('DEV_ULONO_INGEST_RL', 'DEV_ULONO_TRANSFORM_RL', 
                          'DEV_ULONO_ANALYSIS_RL', 'DEV_ULONO_SCIENTIST_RL')
             AND role_name LIKE '%_RL' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.roles
WHERE role_name IN ('DEV_ULONO_INGEST_RL', 'DEV_ULONO_TRANSFORM_RL', 
                    'DEV_ULONO_ANALYSIS_RL', 'DEV_ULONO_SCIENTIST_RL')
ORDER BY role_name;

-- Custom Roles
SELECT 
    'CUSTOM_ROLE' AS role_type,
    role_name,
    comment,
    CASE 
        WHEN role_name IN ('DEV_ULONO_DATA_SCIENTIST_RL', 'DEV_ULONO_ML_ENGINEER_RL', 
                          'DEV_ULONO_PLATFORM_ADMIN_RL')
             AND role_name LIKE '%_RL' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.roles
WHERE role_name IN ('DEV_ULONO_DATA_SCIENTIST_RL', 'DEV_ULONO_ML_ENGINEER_RL', 
                    'DEV_ULONO_PLATFORM_ADMIN_RL')
ORDER BY role_name;

-- Project Admin Role (cross-environment)
SELECT 
    'PROJECT_ADMIN_ROLE' AS role_type,
    role_name,
    comment,
    CASE 
        WHEN role_name = 'ULONO_ADMIN_RL' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.roles
WHERE role_name = 'ULONO_ADMIN_RL';

-- =============================================================================
-- 3. ROLE HIERARCHY VERIFICATION
-- =============================================================================
SELECT 'ROLE HIERARCHY VERIFICATION' AS verification_section;

-- Functional Role Hierarchy: READER -> WRITER -> ADMIN
SELECT 
    'ROLE_HIERARCHY' AS resource_type,
    granted_to_role AS parent_role,
    granted_role AS child_role,
    CASE 
        WHEN (granted_to_role = 'DEV_ULONO_WRITER_RL' AND granted_role = 'DEV_ULONO_READER_RL')
          OR (granted_to_role = 'DEV_ULONO_ADMIN_RL' AND granted_role = 'DEV_ULONO_WRITER_RL')
          OR (granted_to_role = 'ULONO_ADMIN_RL' AND granted_role = 'DEV_ULONO_ADMIN_RL')
          OR (granted_to_role = 'SYSADMIN' AND granted_role = 'ULONO_ADMIN_RL')
        THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.role_grants
WHERE (granted_to_role IN ('DEV_ULONO_READER_RL', 'DEV_ULONO_WRITER_RL', 'DEV_ULONO_ADMIN_RL', 'ULONO_ADMIN_RL', 'SYSADMIN')
   AND granted_role IN ('DEV_ULONO_READER_RL', 'DEV_ULONO_WRITER_RL', 'DEV_ULONO_ADMIN_RL', 'ULONO_ADMIN_RL'))
ORDER BY granted_to_role, granted_role;

-- Data Access Role Grants to Functional Roles
SELECT 
    'DATA_ACCESS_GRANT' AS resource_type,
    granted_to_role AS functional_role,
    granted_role AS data_access_role,
    CASE 
        WHEN (granted_to_role = 'DEV_ULONO_READER_RL' AND granted_role = 'DEV_ULONO_ANALYSIS_RL')
          OR (granted_to_role = 'DEV_ULONO_WRITER_RL' AND granted_role = 'DEV_ULONO_TRANSFORM_RL')
          OR (granted_to_role = 'DEV_ULONO_ADMIN_RL' AND granted_role IN ('DEV_ULONO_INGEST_RL', 'DEV_ULONO_TRANSFORM_RL', 'DEV_ULONO_ANALYSIS_RL', 'DEV_ULONO_SCIENTIST_RL'))
        THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.role_grants
WHERE granted_to_role IN ('DEV_ULONO_READER_RL', 'DEV_ULONO_WRITER_RL', 'DEV_ULONO_ADMIN_RL')
  AND granted_role IN ('DEV_ULONO_INGEST_RL', 'DEV_ULONO_TRANSFORM_RL', 'DEV_ULONO_ANALYSIS_RL', 'DEV_ULONO_SCIENTIST_RL')
ORDER BY granted_to_role, granted_role;

-- Custom Role Inheritance
SELECT 
    'CUSTOM_ROLE_INHERITANCE' AS resource_type,
    granted_to_role AS parent_role,
    granted_role AS custom_role,
    CASE 
        WHEN (granted_to_role = 'DEV_ULONO_READER_RL' AND granted_role = 'DEV_ULONO_DATA_SCIENTIST_RL')
          OR (granted_to_role = 'DEV_ULONO_WRITER_RL' AND granted_role = 'DEV_ULONO_ML_ENGINEER_RL')
          OR (granted_to_role = 'DEV_ULONO_ADMIN_RL' AND granted_role = 'DEV_ULONO_PLATFORM_ADMIN_RL')
        THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.role_grants
WHERE granted_to_role IN ('DEV_ULONO_READER_RL', 'DEV_ULONO_WRITER_RL', 'DEV_ULONO_ADMIN_RL')
  AND granted_role IN ('DEV_ULONO_DATA_SCIENTIST_RL', 'DEV_ULONO_ML_ENGINEER_RL', 'DEV_ULONO_PLATFORM_ADMIN_RL')
ORDER BY granted_to_role, granted_role;

-- =============================================================================
-- 4. DATABASE PERMISSIONS VERIFICATION
-- =============================================================================
SELECT 'DATABASE PERMISSIONS VERIFICATION' AS verification_section;

-- INGEST_RL should have USAGE on DEV_RAW only
SELECT 
    'DATABASE_GRANT' AS resource_type,
    role_name,
    granted_on AS object_type,
    name AS object_name,
    privilege,
    CASE 
        WHEN role_name = 'DEV_ULONO_INGEST_RL' 
         AND name = 'DEV_RAW' 
         AND privilege = 'USAGE' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.grants_to_roles
WHERE role_name = 'DEV_ULONO_INGEST_RL'
  AND granted_on = 'DATABASE'
  AND name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
ORDER BY role_name, name;

-- TRANSFORM_RL should have USAGE on DEV_RAW, DEV_INT, DEV_ANL
SELECT 
    'DATABASE_GRANT' AS resource_type,
    role_name,
    granted_on AS object_type,
    name AS object_name,
    privilege,
    CASE 
        WHEN role_name = 'DEV_ULONO_TRANSFORM_RL' 
         AND name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
         AND privilege = 'USAGE' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.grants_to_roles
WHERE role_name = 'DEV_ULONO_TRANSFORM_RL'
  AND granted_on = 'DATABASE'
  AND name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
ORDER BY role_name, name;

-- ANALYSIS_RL should have USAGE on DEV_ANL only
SELECT 
    'DATABASE_GRANT' AS resource_type,
    role_name,
    granted_on AS object_type,
    name AS object_name,
    privilege,
    CASE 
        WHEN role_name = 'DEV_ULONO_ANALYSIS_RL' 
         AND name = 'DEV_ANL' 
         AND privilege = 'USAGE' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.grants_to_roles
WHERE role_name = 'DEV_ULONO_ANALYSIS_RL'
  AND granted_on = 'DATABASE'
  AND name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
ORDER BY role_name, name;

-- SCIENTIST_RL should have USAGE on DEV_RAW, DEV_INT, DEV_ANL
SELECT 
    'DATABASE_GRANT' AS resource_type,
    role_name,
    granted_on AS object_type,
    name AS object_name,
    privilege,
    CASE 
        WHEN role_name = 'DEV_ULONO_SCIENTIST_RL' 
         AND name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
         AND privilege = 'USAGE' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.grants_to_roles
WHERE role_name = 'DEV_ULONO_SCIENTIST_RL'
  AND granted_on = 'DATABASE'
  AND name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
ORDER BY role_name, name;

-- =============================================================================
-- 5. WAREHOUSE VERIFICATION
-- =============================================================================
SELECT 'WAREHOUSE VERIFICATION' AS verification_section;

SELECT 
    'WAREHOUSE' AS resource_type,
    warehouse_name,
    warehouse_size,
    auto_suspend,
    auto_resume,
    CASE 
        WHEN warehouse_name LIKE 'DEV_ULONO%_WH' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.warehouses
WHERE warehouse_name LIKE 'DEV_ULONO%'
ORDER BY warehouse_name;

-- =============================================================================
-- 6. STAGE AND FILE FORMAT VERIFICATION
-- =============================================================================
SELECT 'STAGE AND FILE FORMAT VERIFICATION' AS verification_section;

-- Stages (should be in DEV_RAW.PUBLIC)
SELECT 
    'STAGE' AS resource_type,
    stage_catalog AS database_name,
    stage_schema AS schema_name,
    stage_name,
    CASE 
        WHEN stage_catalog = 'DEV_RAW' 
         AND stage_schema = 'PUBLIC'
         AND stage_name = 'raw_landing' THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.information_schema.stages
WHERE stage_catalog = 'DEV_RAW'
ORDER BY stage_name;

-- File Formats (should be in DEV_RAW.PUBLIC)
SELECT 
    'FILE_FORMAT' AS resource_type,
    file_format_catalog AS database_name,
    file_format_schema AS schema_name,
    file_format_name,
    format_type,
    CASE 
        WHEN file_format_catalog = 'DEV_RAW' 
         AND file_format_schema = 'PUBLIC'
         AND file_format_name IN ('csv_standard', 'json_standard') THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.information_schema.file_formats
WHERE file_format_catalog = 'DEV_RAW'
ORDER BY file_format_name;

-- =============================================================================
-- 7. TAG VERIFICATION
-- =============================================================================
SELECT 'TAG VERIFICATION' AS verification_section;

-- Role Tags
SELECT 
    'ROLE_TAG' AS resource_type,
    OBJECT_NAME AS role_name,
    TAG_DATABASE || '.' || TAG_SCHEMA || '.' || TAG_NAME AS tag_name,
    TAG_VALUE,
    CASE 
        WHEN TAG_NAME IN ('ENVIRONMENT', 'PROJECT', 'TERRAFORM_MANAGED')
         AND TAG_VALUE IN ('DEV', 'ulono', 'true') THEN '✅ EXPECTED'
        ELSE '❌ UNEXPECTED'
    END AS status
FROM snowflake.account_usage.tag_references
WHERE OBJECT_DATABASE IS NULL
  AND OBJECT_SCHEMA IS NULL
  AND OBJECT_NAME LIKE 'DEV_ULONO%_RL'
ORDER BY OBJECT_NAME, TAG_NAME;

-- =============================================================================
-- 8. SUMMARY REPORT
-- =============================================================================
SELECT 'SUMMARY REPORT' AS verification_section;

SELECT 
    'SUMMARY' AS report_type,
    COUNT(DISTINCT CASE WHEN database_name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL') THEN database_name END) AS databases_created,
    COUNT(DISTINCT CASE WHEN role_name LIKE 'DEV_ULONO%_RL' OR role_name = 'ULONO_ADMIN_RL' THEN role_name END) AS roles_created,
    COUNT(DISTINCT CASE WHEN warehouse_name LIKE 'DEV_ULONO%_WH' THEN warehouse_name END) AS warehouses_created,
    COUNT(DISTINCT CASE WHEN stage_catalog = 'DEV_RAW' THEN stage_name END) AS stages_created,
    COUNT(DISTINCT CASE WHEN file_format_catalog = 'DEV_RAW' THEN file_format_name END) AS file_formats_created
FROM (
    SELECT catalog_name AS database_name FROM information_schema.databases WHERE catalog_name IN ('DEV_RAW', 'DEV_INT', 'DEV_ANL')
    UNION ALL
    SELECT role_name FROM snowflake.account_usage.roles WHERE role_name LIKE 'DEV_ULONO%_RL' OR role_name = 'ULONO_ADMIN_RL'
    UNION ALL
    SELECT warehouse_name FROM snowflake.account_usage.warehouses WHERE warehouse_name LIKE 'DEV_ULONO%'
    UNION ALL
    SELECT stage_name FROM snowflake.information_schema.stages WHERE stage_catalog = 'DEV_RAW'
    UNION ALL
    SELECT file_format_name FROM snowflake.information_schema.file_formats WHERE file_format_catalog = 'DEV_RAW'
);

-- =============================================================================
-- VERIFICATION COMPLETE
-- =============================================================================
SELECT 'VERIFICATION COMPLETE' AS verification_section;
SELECT 'Review the results above. All items marked ✅ EXPECTED should be present.' AS instructions;
SELECT 'If any items show ❌ UNEXPECTED, check the Terraform apply output for errors.' AS next_steps;

