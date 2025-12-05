# Basic example of using the Terraform Snowflake Account Objects module
# This example demonstrates setting up the foundation infrastructure

# Configure Snowflake Provider
provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account_name
  user              = var.snowflake_username
  password          = var.snowflake_password
  role              = "ACCOUNTADMIN"
}

# Use the Snowflake Account Objects module
module "snowflake_foundation" {
  source = "../.."

  # Project configuration
  project_name = var.project_name
  environment  = var.environment

  # Feature flags
  enable_rbac          = true
  enable_tagging       = true
  enable_databases     = true
  create_tag_schema    = true
  create_default_roles = true

  # Default tags
  default_tags = {
    managed_by   = "terraform"
    cost_center  = var.cost_center
    owner        = var.owner_email
    created_date = timestamp()
  }
}

# Example: Create a database
# Note: The module creates databases based on the 'databases' variable
# This is just an example of creating an additional database outside the module
resource "snowflake_database" "main" {
  name    = upper("${var.environment}_${var.project_name}_DB_MAIN")
  comment = "Main database for ${var.project_name} ${var.environment}"

  data_retention_time_in_days = var.environment == "prod" ? 7 : 1
}

# Example: Apply tags to the database
# Note: Tag associations may have different syntax in v2.0
# This is commented out until we verify the correct syntax
# resource "snowflake_tag_association" "database_tags" {
#   for_each = module.snowflake_foundation.governance_tags
#
#   object_identifiers = [{
#     name     = snowflake_database.main.name
#     database = snowflake_database.main.name
#   }]
#   
#   object_type = "DATABASE"
#   tag_id      = "${each.value.database}.${each.value.schema}.${each.value.name}"
#   tag_value   = lookup(module.snowflake_foundation.common_tags, lower(each.key), "N/A")
# } 