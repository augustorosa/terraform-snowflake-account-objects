# Authentication Features Test

This directory contains a comprehensive test configuration for all authentication features implemented in the Terraform Snowflake Account Objects module.

## Features Being Tested

### 🔑 RSA Key-Pair Authentication
- **Service users**: 3 test service accounts with different roles
- **Key rotation**: Primary and secondary key support
- **Expiry management**: Different expiry settings for testing
- **Role assignment**: Integration with RBAC system

### 🎫 Personal Access Tokens (PAT)
- **Token creation**: 3 PAT tokens for different use cases
- **Role restrictions**: Tokens limited to specific roles
- **Expiry controls**: Short expiry times for testing
- **Network policy bypass**: Different bypass settings
- **Token rotation**: Automatic rotation configuration

### 🌐 Network Policies
- **Network rules**: Corporate, GitHub Actions, and local dev IP ranges
- **Network policies**: Service accounts and human users policies
- **Default policy**: Permissive policy for testing
- **IP restrictions**: Comprehensive IP-based access control

### 👥 RBAC Integration
- **Default roles**: READER, WRITER, ADMIN hierarchy
- **Custom roles**: TOKEN_ADMIN and SECURITY_AUDITOR
- **Role inheritance**: Proper role relationships
- **Service user assignment**: Users assigned to appropriate roles

## Test Configuration

The test creates:
- **3 Service Users** with different permission levels
- **3 PAT Tokens** with various restrictions
- **3 Network Rules** covering different IP ranges
- **2 Network Policies** for different user types
- **1 Default Network Policy** for baseline access
- **5 Custom Roles** (3 default + 2 custom)
- **Tag Schema** for proper resource organization

## Usage

### Prerequisites

1. **Snowflake Account**: Enterprise Edition recommended for all features
2. **Network Policies**: Required for PAT tokens to function
3. **Proper Permissions**: ACCOUNTADMIN or equivalent privileges
4. **Provider Configuration**: Snowflake provider 2.4.0

### Running the Test

```bash
# Navigate to test directory
cd test/authentication-test

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration (requires Snowflake credentials)
terraform apply
```

### Expected Resources

After successful deployment:

```
Plan: 15 to add, 0 to change, 0 to destroy.

Resources created:
- 3 Service users
- 3 PAT tokens  
- 3 Network rules
- 3 Network policies (2 custom + 1 default)
- 5 RBAC roles
- 1 Tag database and schema
- Multiple tags
```

## Security Notes

### 🔒 Production Considerations

1. **RSA Keys**: The test uses placeholder comments for keys. In production:
   - Generate keys using OpenSSL or the provided UDTF
   - Store private keys securely (HashiCorp Vault, AWS Secrets Manager)
   - Use strong passphrases for encrypted keys

2. **Network Policies**: The test uses permissive IP ranges. In production:
   - Restrict to specific corporate IP ranges
   - Use VPN or private connectivity
   - Regularly audit and update IP allowlists

3. **PAT Tokens**: Test tokens have short expiry. In production:
   - Use appropriate expiry times (90+ days)
   - Implement token rotation workflows
   - Monitor token usage and disable unused tokens

4. **Role Restrictions**: Test uses broad role assignments. In production:
   - Follow principle of least privilege
   - Use specific role restrictions per token
   - Regular access reviews and audits

### 🧹 Cleanup

To destroy test resources:

```bash
terraform destroy
```

**Important**: This will delete all created resources. Ensure this is a test environment only.

## Troubleshooting

### Common Issues

1. **Network Policy Errors**: 
   - Ensure default network policy is applied to account
   - Check IP ranges are valid CIDR notation

2. **PAT Token Creation Fails**:
   - Verify network policies are active
   - Check user has proper role assignments
   - Ensure service users exist before creating tokens

3. **Service User Creation Issues**:
   - Verify RBAC roles exist
   - Check email format is valid
   - Ensure proper naming conventions

### Validation Commands

After deployment, validate with:

```sql
-- Check service users
SHOW USERS LIKE 'AUTH_TEST_%';

-- Check network policies  
SHOW NETWORK POLICIES;

-- Check roles
SHOW ROLES LIKE 'AUTH_TEST_%';

-- Check PAT tokens (requires proper permissions)
SHOW USER FUNCTIONS;
```

## Integration with CI/CD

This test configuration can be integrated into CI/CD pipelines for:

- **Automated testing** of authentication features
- **Regression testing** after provider updates  
- **Security validation** of authentication patterns
- **Documentation validation** through working examples

The test serves as both validation and living documentation for the module's authentication capabilities. 