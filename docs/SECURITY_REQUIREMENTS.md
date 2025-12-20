# Security Requirements

## 1. Overview

This document outlines the security requirements for the Terraform Snowflake Account Objects module, incorporating best practices from Snowflake's MFA migration guide and modern cloud security principles.

## 2. Authentication Requirements

### 2.1 User Type Classification

Based on [Snowflake's MFA migration best practices](https://docs.snowflake.com/en/user-guide/security-mfa-migration-best-practices), all users MUST be classified with the appropriate TYPE attribute:

#### User Types
- **PERSON**: Human users requiring interactive authentication with MFA enforcement
- **SERVICE**: Service accounts for programmatic access (OAuth or key-pair only)
- **LEGACY_SERVICE**: Temporary migration type for legacy systems (deprecated November 2025)

```sql
-- Example user type assignments
ALTER USER john_doe SET TYPE = 'PERSON';
ALTER USER dbt_service SET TYPE = 'SERVICE';
ALTER USER legacy_etl SET TYPE = 'LEGACY_SERVICE'; -- Temporary only!
```

### 2.2 Authentication Methods by User Type

| User Type | Allowed Authentication | MFA Required | Notes |
|-----------|----------------------|--------------|--------|
| PERSON | Password + MFA, SAML SSO + MFA | Yes | Interactive users only |
| SERVICE | Key-pair, OAuth, PAT | No | No password authentication |
| LEGACY_SERVICE | Password only | No | Deprecating November 2025 |

### 2.3 Multi-Factor Authentication (MFA)

**Account-Level MFA Enforcement Policy**:
```sql
CREATE AUTHENTICATION POLICY ENFORCE_MFA_FOR_HUMANS
  AUTHENTICATION_METHODS = ('PASSWORD', 'SAML')
  MFA_AUTHENTICATION_METHODS = ('PASSWORD', 'SAML')
  MFA_ENROLLMENT = 'REQUIRED'
  CLIENT_TYPES = ('SNOWFLAKE_UI', 'DRIVERS', 'SNOWSQL');

-- Apply at account level
ALTER ACCOUNT SET AUTHENTICATION POLICY = ENFORCE_MFA_FOR_HUMANS;
```

**Double MFA for Privileged Users**:
```sql
CREATE AUTHENTICATION POLICY ACCOUNTADMIN_DOUBLE_MFA
  AUTHENTICATION_METHODS = ('SAML')
  MFA_AUTHENTICATION_METHODS = ('SAML')
  MFA_ENROLLMENT = 'REQUIRED';

ALTER USER privileged_admin SET AUTHENTICATION POLICY = ACCOUNTADMIN_DOUBLE_MFA;
```

## 3. Network Security Requirements

### 3.1 Network Policies

All accounts MUST implement network policies based on user type and access patterns:

```sql
-- Human users network policy
CREATE NETWORK RULE HUMAN_ACCESS_NET_RULE
  TYPE = IPV4
  VALUE_LIST = ('10.0.0.0/8', '172.16.0.0/12')  -- Corporate network
  MODE = INGRESS;

CREATE NETWORK POLICY HUMAN_ACCESS_POLICY
  ALLOWED_NETWORK_RULE_LIST = ('HUMAN_ACCESS_NET_RULE');

-- Service account network policy  
CREATE NETWORK RULE SERVICE_ACCESS_NET_RULE
  TYPE = IPV4
  VALUE_LIST = ('10.1.0.0/24', '52.1.2.3/32')  -- Specific service IPs
  MODE = INGRESS;

CREATE NETWORK POLICY SERVICE_ACCESS_POLICY
  ALLOWED_NETWORK_RULE_LIST = ('SERVICE_ACCESS_NET_RULE');
```

### 3.2 Private Connectivity

For production environments, implement private connectivity where possible:
- AWS PrivateLink
- Azure Private Endpoints
- GCP Private Service Connect

## 4. Session Security

### 4.1 Session Policies

```sql
CREATE SESSION POLICY HUMAN_SESSION_POLICY
  SESSION_UI_IDLE_TIMEOUT_MINS = 30
  SESSION_IDLE_TIMEOUT_MINS = 240;

CREATE SESSION POLICY SERVICE_SESSION_POLICY
  SESSION_IDLE_TIMEOUT_MINS = 60;

-- Apply policies
ALTER ACCOUNT SET SESSION POLICY = HUMAN_SESSION_POLICY;
ALTER USER service_account SET SESSION POLICY = SERVICE_SESSION_POLICY;
```

### 4.2 Password Policies

```sql
CREATE PASSWORD POLICY STRONG_PASSWORD_POLICY
  PASSWORD_MIN_LENGTH = 14
  PASSWORD_MIN_UPPER_CASE_CHARS = 1
  PASSWORD_MIN_LOWER_CASE_CHARS = 1
  PASSWORD_MIN_NUMERIC_CHARS = 1
  PASSWORD_MIN_SPECIAL_CHARS = 1
  PASSWORD_MAX_AGE_DAYS = 90
  PASSWORD_MAX_RETRIES = 3
  PASSWORD_LOCKOUT_TIME_MINS = 30
  PASSWORD_HISTORY = 5;

ALTER ACCOUNT SET PASSWORD POLICY = STRONG_PASSWORD_POLICY;
```

## 5. Access Control Requirements

### 5.1 Role-Based Access Control (RBAC)

- Implement principle of least privilege
- Use hierarchical role structure
- Separate roles by function and data layer
- No direct table access for end users

### 5.2 Data Access Patterns

```yaml
# Layer-based access control
access_control:
  raw_layer:
    write: ["loader_roles", "service_accounts"]
    read: ["transformer_roles", "engineers"]
    
  prepare_layer:
    write: ["transformer_roles"]
    read: ["analyst_roles", "engineers"]
    
  analyze_layer:
    write: ["transformer_roles"]
    read: ["all_business_users"]
```

## 6. Data Protection

### 6.1 Encryption

**At Rest**:
- All data encrypted using AES-256
- Customer-managed keys (CMK) for sensitive data
- Key rotation every 90 days

**In Transit**:
- TLS 1.2 minimum
- Certificate validation required
- No unencrypted endpoints

### 6.2 Data Masking

```sql
-- Dynamic data masking for PII
CREATE MASKING POLICY mask_pii AS (val string) 
  RETURNS string ->
    CASE
      WHEN CURRENT_ROLE() IN ('ANALYST') THEN '***MASKED***'
      ELSE val
    END;

-- Apply to sensitive columns
ALTER TABLE customers MODIFY COLUMN ssn SET MASKING POLICY mask_pii;
```

### 6.3 Row-Level Security

```sql
CREATE ROW ACCESS POLICY region_policy AS (region_name varchar) 
  RETURNS boolean ->
    CASE
      WHEN CURRENT_ROLE() = 'GLOBAL_ADMIN' THEN TRUE
      WHEN CURRENT_ROLE() = 'REGIONAL_ANALYST' AND region_name = CURRENT_REGION() THEN TRUE
      ELSE FALSE
    END;
```

## 7. Auto-Tagging Requirements

### 7.1 Mandatory Tags

All Snowflake objects MUST be tagged with:

```sql
-- Create tag definitions
CREATE TAG governance.environment ALLOWED_VALUES 'dev', 'staging', 'prod';
CREATE TAG governance.data_classification ALLOWED_VALUES 'public', 'internal', 'confidential', 'restricted';
CREATE TAG governance.owner;
CREATE TAG governance.cost_center;
CREATE TAG governance.created_by;
CREATE TAG governance.created_date;
CREATE TAG governance.project;

-- Auto-tagging implementation
CREATE PROCEDURE auto_tag_object(object_type STRING, object_name STRING)
  RETURNS STRING
  LANGUAGE SQL
  AS
  $$
  BEGIN
    -- Apply mandatory tags
    EXECUTE IMMEDIATE 'ALTER ' || object_type || ' ' || object_name || 
      ' SET TAG governance.created_by = ''' || CURRENT_USER() || '''';
    EXECUTE IMMEDIATE 'ALTER ' || object_type || ' ' || object_name || 
      ' SET TAG governance.created_date = ''' || CURRENT_TIMESTAMP() || '''';
    EXECUTE IMMEDIATE 'ALTER ' || object_type || ' ' || object_name || 
      ' SET TAG governance.environment = ''' || SPLIT_PART(object_name, '_', 1) || '''';
    RETURN 'Tags applied successfully';
  END;
  $$;
```

### 7.2 Tag Governance

```yaml
tag_governance:
  mandatory_tags:
    - environment
    - data_classification
    - owner
    - cost_center
    - project
    
  auto_applied_tags:
    - created_by
    - created_date
    - last_modified_by
    - last_modified_date
    
  tag_policies:
    - name: "enforce_mandatory_tags"
      action: "block_creation"
      message: "Object must have all mandatory tags"
```

## 8. Monitoring and Auditing

### 8.1 Security Monitoring

Monitor these security events:
- Failed login attempts
- Privilege escalations
- Network policy violations
- Data access anomalies
- Service account usage patterns

```sql
-- Monitor failed logins
CREATE ALERT monitor_failed_logins
  WAREHOUSE = SECURITY_WH
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE IS_SUCCESS = 'NO'
      AND EVENT_TIMESTAMP > DATEADD('MINUTE', -5, CURRENT_TIMESTAMP())
    HAVING COUNT(*) > 5
  ))
  THEN CALL system$send_email(
    'security-team@company.com',
    'Failed Login Alert',
    'Multiple failed login attempts detected'
  );
```

### 8.2 Trust Center Integration

Leverage Snowflake Trust Center for:
- MFA enrollment status
- Network policy coverage
- Inactive user detection
- Password policy compliance
- Leaked password detection

## 9. Security Best Practices Checklist

### 9.1 Initial Setup
- [ ] Enable organization feature
- [ ] Configure SCIM for user provisioning
- [ ] Set user TYPE attributes correctly
- [ ] Implement MFA enforcement policy
- [ ] Configure network policies
- [ ] Set up session policies
- [ ] Enable auto-tagging
- [ ] Configure Trust Center

### 9.2 Ongoing Security
- [ ] Monitor Trust Center findings weekly
- [ ] Review inactive users (90+ days)
- [ ] Rotate service account keys quarterly
- [ ] Update network policies as needed
- [ ] Review and update data classifications
- [ ] Audit privileged access monthly
- [ ] Test break-glass procedures

### 9.3 Migration from Legacy Patterns
- [ ] Identify all LEGACY_SERVICE users
- [ ] Plan migration to SERVICE type
- [ ] Implement PAT tokens where needed
- [ ] Update applications for key-pair auth
- [ ] Remove password authentication
- [ ] Complete migration before November 2025

## 10. Break-Glass Procedures

```sql
-- Break-glass account with reduced MFA
CREATE USER break_glass_admin
  TYPE = 'PERSON'
  DEFAULT_ROLE = 'ACCOUNTADMIN'
  MUST_CHANGE_PASSWORD = FALSE;

CREATE AUTHENTICATION POLICY BREAK_GLASS_POLICY
  AUTHENTICATION_METHODS = ('PASSWORD')
  MFA_AUTHENTICATION_METHODS = ('PASSWORD')
  MFA_ENROLLMENT = 'OPTIONAL';

ALTER USER break_glass_admin SET AUTHENTICATION POLICY = BREAK_GLASS_POLICY;

-- Monitor break-glass usage
CREATE ALERT monitor_break_glass
  WAREHOUSE = SECURITY_WH
  SCHEDULE = '1 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE USER_NAME = 'BREAK_GLASS_ADMIN'
      AND EVENT_TIMESTAMP > DATEADD('MINUTE', -1, CURRENT_TIMESTAMP())
  ))
  THEN CALL system$send_email(
    'security-team@company.com',
    'CRITICAL: Break-Glass Account Used',
    'Break-glass account accessed. Immediate investigation required.'
  );
```

## 11. Compliance Mapping

### 11.1 SOC2 Controls
- CC6.1: Logical and physical access controls
- CC6.2: User access provisioning
- CC6.3: User authentication
- CC7.2: System monitoring

### 11.2 HIPAA Requirements
- Access control (164.312(a)(1))
- Audit controls (164.312(b))
- Integrity controls (164.312(c)(1))
- Encryption (164.312(a)(2)(iv))

### 11.3 PCI DSS
- Requirement 7: Restrict access
- Requirement 8: Identify and authenticate
- Requirement 10: Track and monitor access
- Requirement 11: Test security systems 