# Basic Example

This example demonstrates the foundational setup for managing Snowflake resources with Terraform, including:
- Setting up naming conventions
- Creating tag schemas
- Establishing default roles
- Creating a sample database with proper naming and tagging

## Prerequisites

1. Snowflake account with appropriate privileges
2. Terraform >= 1.5.7
3. Valid Snowflake credentials

## Usage

1. **Copy and configure terraform.tfvars:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review the plan:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## What Gets Created

### Foundation Resources
- **Tag Database**: `{ENV}_{PROJECT}_TAGS_DB` (e.g., `DEV_ANALYTICS_TAGS_DB`)
- **Tag Schema**: `TAG_DEFINITIONS` schema within the tag database
- **Tags**: Governance, operational, and technical tags
- **Default Roles**: 
  - `{ENV}_{PROJECT}_LOADER_ROLE`
  - `{ENV}_{PROJECT}_TRANSFORMER_ROLE`
  - `{ENV}_{PROJECT}_REPORTER_ROLE`
  - `{ENV}_{PROJECT}_ANALYST_ROLE`
  - `{ENV}_{PROJECT}_DATA_ENGINEER_ROLE`
  - `{ENV}_{PROJECT}_DATA_SCIENTIST_ROLE`
- **Validation Procedure**: For checking naming conventions

### Example Resources
- **Main Database**: `{ENV}_{PROJECT}_DB_MAIN` with appropriate tags

## Outputs

After applying, you'll see:
- `naming_prefix`: The prefix to use for all resources
- `default_roles`: List of roles created
- `naming_examples`: Examples of properly named resources
- `validation_procedure`: Details for the naming validation function

## Using the Validation Procedure

After deployment, you can validate resource names:

```sql
CALL DEV_ANALYTICS_TAGS_DB.TAG_DEFINITIONS.VALIDATE_NAMING_CONVENTION('database', 'DEV_ANALYTICS_DB_RAW');
-- Returns: 'VALID'

CALL DEV_ANALYTICS_TAGS_DB.TAG_DEFINITIONS.VALIDATE_NAMING_CONVENTION('database', 'WRONG_NAME');
-- Returns: Error message with expected format
```

## Environment Variables

For better security, use environment variables for sensitive values:

```bash
export TF_VAR_snowflake_password="your-secure-password"
export TF_VAR_snowflake_private_key="$(cat ~/.snowflake/rsa_key.p8)"
```

## Next Steps

1. Use the foundation outputs in other modules
2. Create databases following the naming convention
3. Apply tags to all resources
4. Grant appropriate permissions to the default roles

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the tag database and roles. 