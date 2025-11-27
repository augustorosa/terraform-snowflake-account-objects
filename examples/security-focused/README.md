# 🔐 **Security-Focused Example - Provider 2.7.0 Features**

This example demonstrates all the latest **account-level security features** available in Snowflake Terraform Provider 2.7.0, implementing a comprehensive security-first approach to Snowflake account management.

## 🎯 **Features Demonstrated**

### **🆕 New in Provider 2.7.0**
- ✅ **Authentication Policies** - Enforce MFA and authentication methods
- ✅ **External OAuth Integrations** - Workload identity federation
- ✅ **Enhanced Connection Management** - Improved stability and logging

### **🔒 Comprehensive Security Stack**
- ✅ **Service Users** with RSA key-pair authentication
- ✅ **PAT Tokens** with role restrictions and network policy integration
- ✅ **Network Policies** with IP-based access control
- ✅ **RBAC Hierarchy** with security-focused custom roles
- ✅ **Auto-Classification** for data governance
- ✅ **Resource Tagging** for security compliance

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                    SNOWFLAKE ACCOUNT                        │
├─────────────────────────────────────────────────────────────┤
│  🔐 AUTHENTICATION LAYER                                    │
│  ├── Authentication Policies (MFA enforcement)             │
│  ├── External OAuth Integrations (Workload Identity)       │
│  ├── Service Users (RSA key-pair auth)                     │
│  └── PAT Tokens (Network policy integration)               │
├─────────────────────────────────────────────────────────────┤
│  🌐 NETWORK SECURITY LAYER                                  │
│  ├── Network Rules (IP ranges)                             │
│  ├── Network Policies (User type restrictions)             │
│  └── Default Network Policy (Baseline security)            │
├─────────────────────────────────────────────────────────────┤
│  👥 RBAC LAYER                                              │
│  ├── Default Roles (READER → WRITER → ADMIN)               │
│  ├── Security Admin Role                                   │
│  ├── Compliance Auditor Role                               │
│  └── Service Account Manager Role                          │
├─────────────────────────────────────────────────────────────┤
│  🏷️ GOVERNANCE LAYER                                        │
│  ├── Auto-Classification (Data sensitivity)                │
│  ├── Security Tags (Classification, Compliance)            │
│  └── Operational Tags (Contacts, Audit frequency)          │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **1. Prerequisites**
- Snowflake account with **ACCOUNTADMIN** privileges
- Terraform >= 1.5.7
- Snowflake Terraform Provider 2.7.0

### **2. Configuration**
```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your specific values
vi terraform.tfvars
```

### **3. Deploy**
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## 📋 **Configuration Examples**

### **Authentication Policies**
```hcl
authentication_policies = {
  "MFA_REQUIRED_HUMANS" = {
    comment                    = "Enforce MFA for all human users"
    authentication_methods     = ["PASSWORD", "SAML"]
    mfa_authentication_methods = ["PASSWORD", "SAML"]
    mfa_enrollment            = "REQUIRED"
    client_types              = ["SNOWFLAKE_UI", "DRIVERS", "SNOWSQL"]
  }
  "SERVICE_ACCOUNTS_OAUTH" = {
    comment                = "Service accounts - OAuth/JWT only"
    authentication_methods = ["OAUTH", "JWT"]
    mfa_enrollment        = "OPTIONAL"
    client_types          = ["DRIVERS", "SNOWSQL"]
  }
}
```

### **Workload Identity Federation**
```hcl
external_oauth_integrations = {
  "GITHUB_ACTIONS" = {
    type                  = "EXTERNAL_OAUTH"
    external_oauth_type   = "CUSTOM"
    external_oauth_issuer = "https://token.actions.githubusercontent.com"
    external_oauth_audience_list = ["https://github.com/your-org"]
    external_oauth_token_user_mapping_claim = "sub"
  }
  "AWS_WORKLOAD_IDENTITY" = {
    type                  = "EXTERNAL_OAUTH"
    external_oauth_type   = "CUSTOM"
    external_oauth_issuer = "https://oidc.eks.us-west-2.amazonaws.com/id/CLUSTER-ID"
    external_oauth_audience_list = ["sts.amazonaws.com"]
  }
}
```

### **Service Users with Key-Pair Auth**
```hcl
service_users = {
  "TERRAFORM_SERVICE" = {
    comment           = "Terraform automation service user"
    default_role      = "SYSADMIN"
    email            = "terraform@company.com"
    days_to_expiry   = 365
    rsa_public_key   = "base64_encoded_public_key_here"
  }
}
```

## 🔧 **Customization**

### **Network Security**
Customize IP ranges and network policies in `variables.tf`:
```hcl
variable "allowed_ip_ranges" {
  default = [
    "10.0.0.0/8",      # Your corporate network
    "172.16.0.0/12",   # Your VPN ranges
    "203.0.113.0/24",  # Your cloud provider IPs
  ]
}
```

### **Authentication Requirements**
Adjust MFA and authentication policies:
```hcl
# Require MFA for all users
mfa_enrollment = "REQUIRED"

# Allow only specific authentication methods
authentication_methods = ["SAML"]  # SSO only
```

### **Role Hierarchy**
Add custom roles for your organization:
```hcl
custom_roles = {
  "DATA_SCIENTIST" = {
    comment = "Data science team role"
  }
  "EXTERNAL_AUDITOR" = {
    comment = "External audit access role"
  }
}
```

## 📊 **Monitoring & Compliance**

### **Security Outputs**
The example provides comprehensive outputs for monitoring:
- Authentication policies status
- OAuth integrations configuration
- Service users and PAT tokens
- Network policies effectiveness
- Security setup checklist

### **Compliance Features**
- **Auto-tagging** for regulatory compliance
- **Data classification** for sensitive data identification
- **Audit trails** through comprehensive logging
- **Access controls** with role-based permissions

## 🔍 **Testing & Validation**

### **Authentication Testing**
```bash
# Test OAuth integration
snowsql -a your-account -u your-user --authenticator externalbrowser

# Test PAT token
snowsql -a your-account -u your-user --authenticator oauth --token your-pat-token

# Test key-pair authentication
snowsql -a your-account -u your-service-user --private-key-path private_key.p8
```

### **Network Policy Testing**
```bash
# Test from allowed IP
snowsql -a your-account -u your-user

# Test from blocked IP (should fail)
# Use VPN or different network to test restrictions
```

## 🚨 **Security Best Practices**

### **Key Management**
1. **Generate strong RSA keys** (2048-bit minimum)
2. **Store private keys securely** (encrypted, access-controlled)
3. **Implement key rotation** (quarterly recommended)
4. **Use separate keys** for different environments

### **Network Security**
1. **Whitelist specific IP ranges** (avoid 0.0.0.0/0)
2. **Separate policies** for humans vs. service accounts
3. **Regular IP range reviews** (quarterly)
4. **Monitor failed connection attempts**

### **Authentication**
1. **Enforce MFA** for all human users
2. **Use OAuth/JWT** for service accounts
3. **Short-lived PAT tokens** (30-90 days max)
4. **Role restrictions** on all tokens

### **Monitoring**
1. **Enable Trust Center notifications**
2. **Monitor authentication failures**
3. **Regular access reviews** (monthly)
4. **Automated compliance reporting**

## 📚 **Additional Resources**

- [Provider 2.7.0 Migration Guide](../../docs/PROVIDER_2.7.0_MIGRATION.md)
- [Snowflake Security Best Practices](https://docs.snowflake.com/en/user-guide/security)
- [Authentication Policies Documentation](https://docs.snowflake.com/en/sql-reference/sql/create-authentication-policy)
- [External OAuth Integration Guide](https://docs.snowflake.com/en/sql-reference/sql/create-security-integration-oauth-external)

## 🤝 **Contributing**

This example is part of the broader Terraform Snowflake Account Objects module. Contributions and improvements are welcome!

---

**🔐 This example implements enterprise-grade security controls using the latest Snowflake and Terraform provider features. Perfect for organizations requiring comprehensive account-level security management!**
