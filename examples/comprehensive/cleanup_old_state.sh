#!/bin/bash
# Remove old resources from state to allow new structure

echo "Removing old databases from state..."
terraform state rm 'module.snowflake_account_objects.snowflake_database.databases["analytics"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_database.databases["staging"]' 2>/dev/null || true

echo "Removing old database tag associations..."
terraform state rm -state=terraform.tfstate 'module.snowflake_account_objects.snowflake_tag_association.database_environment["analytics"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_tag_association.database_environment["staging"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_tag_association.database_module_version["analytics"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_tag_association.database_module_version["staging"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_tag_association.database_project["analytics"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_tag_association.database_project["staging"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_tag_association.database_terraform_managed["analytics"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_tag_association.database_terraform_managed["staging"]' 2>/dev/null || true

echo "Removing old roles from state..."
terraform state rm 'module.snowflake_account_objects.snowflake_account_role.data_access_roles["ALL_DATA"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_account_role.data_access_roles["ANALYSIS_ONLY"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_account_role.data_access_roles["INGEST_ONLY"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_account_role.custom_functional_roles["data_scientist"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_account_role.custom_functional_roles["ml_engineer"]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_account_role.custom_functional_roles["platform_admin"]' 2>/dev/null || true

echo "Removing old role grants..."
terraform state rm 'module.snowflake_account_objects.snowflake_grant_account_role.all_data_to_admin[0]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_grant_account_role.analysis_only_to_admin[0]' 2>/dev/null || true
terraform state rm 'module.snowflake_account_objects.snowflake_grant_account_role.ingest_only_to_admin[0]' 2>/dev/null || true

echo "✅ Cleanup complete. Old resources removed from state."
echo "Note: Resources still exist in Snowflake but are no longer managed by Terraform."
