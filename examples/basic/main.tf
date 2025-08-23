# Basic example of using the Terraform Snowflake Account Objects module
# This example demonstrates setting up the foundation infrastructure

terraform {
  required_version = ">= 1.5.7"

  # Configure your backend here (S3, Azure Blob, GCS, etc.)
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "snowflake/basic/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# Use the Snowflake Account Objects module
module "snowflake_foundation" {
  source = "../.."

  # Snowflake authentication
  snowflake_organization = var.snowflake_organization
  snowflake_account_name = var.snowflake_account_name
  snowflake_username     = var.snowflake_username
  snowflake_password     = var.snowflake_password

  # Project configuration
  project_name = var.project_name
  environment  = var.environment

  # Feature flags
  enable_auto_tagging       = true
  create_tag_schema         = true
  create_default_roles      = true
  strict_naming_enforcement = true

  # Default tags
  default_tags = {
    managed_by   = "terraform"
    cost_center  = var.cost_center
    owner        = var.owner_email
    created_date = timestamp()
  }
}

# Example: Create a database using module outputs
resource "snowflake_database" "main" {
  name    = "${module.snowflake_foundation.naming_prefix}_DB_MAIN"
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