terraform {
  required_version = ">= 1.14.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.11.0"
    }
  }
}