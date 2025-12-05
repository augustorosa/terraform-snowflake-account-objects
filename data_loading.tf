# =============================================================================
# DATA LOADING INFRASTRUCTURE
# =============================================================================

# Create stages
resource "snowflake_stage" "stages" {
  for_each = var.enable_data_loading ? var.stages : {}

  database = each.value.database
  schema   = each.value.schema
  name     = each.key

  comment = each.value.comment != "" ? each.value.comment : "Stage ${each.key} - Managed by Terraform"

  # Stage type and location
  url = each.value.url

  # Credentials
  credentials = each.value.credentials

  # File format
  file_format = each.value.file_format

  # Copy options
  copy_options = each.value.copy_options

  # Directory settings
  directory = each.value.directory
}

# Create file formats
resource "snowflake_file_format" "file_formats" {
  for_each = var.enable_data_loading ? var.file_formats : {}

  database = each.value.database
  schema   = each.value.schema
  name     = each.key

  format_type = each.value.format_type
  comment     = each.value.comment != "" ? each.value.comment : "File format ${each.key} - Managed by Terraform"

  # Format-specific options
  compression                    = each.value.compression
  record_delimiter               = each.value.record_delimiter
  field_delimiter                = each.value.field_delimiter
  field_optionally_enclosed_by   = each.value.field_optionally_enclosed_by
  skip_header                    = each.value.skip_header
  skip_blank_lines               = each.value.skip_blank_lines
  date_format                    = each.value.date_format
  time_format                    = each.value.time_format
  timestamp_format               = each.value.timestamp_format
  binary_format                  = each.value.binary_format
  escape                         = each.value.escape
  escape_unenclosed_field        = each.value.escape_unenclosed_field
  trim_space                     = each.value.trim_space
  error_on_column_count_mismatch = each.value.error_on_column_count_mismatch
  replace_invalid_characters     = each.value.replace_invalid_characters
  empty_field_as_null            = each.value.empty_field_as_null
  null_if                        = each.value.null_if
  encoding                       = each.value.encoding
}
