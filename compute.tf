# =============================================================================
# COMPUTE RESOURCES
# =============================================================================
# This file contains:
# - Warehouses (compute clusters)
# - Resource monitors (cost control)
# =============================================================================

# =============================================================================
# WAREHOUSES
# =============================================================================

resource "snowflake_warehouse" "warehouses" {
  for_each = var.enable_warehouses ? var.warehouses : {}

  name    = "${local.base_prefix}_${upper(each.key)}_WH"
  comment = coalesce(each.value.comment, "Warehouse ${each.key} for ${var.project_name} ${var.environment} - Managed by Terraform")

  warehouse_size    = each.value.size
  min_cluster_count = each.value.min_cluster_count
  max_cluster_count = each.value.max_cluster_count
  scaling_policy    = each.value.scaling_policy
  
  auto_suspend        = each.value.auto_suspend
  auto_resume         = each.value.auto_resume
  initially_suspended = each.value.initially_suspended
  
  resource_monitor = each.value.resource_monitor != "" ? each.value.resource_monitor : null
  
  enable_query_acceleration           = each.value.enable_query_acceleration
  query_acceleration_max_scale_factor = each.value.query_acceleration_max_scale_factor
}

# =============================================================================
# RESOURCE MONITORS
# =============================================================================

resource "snowflake_resource_monitor" "resource_monitors" {
  for_each = var.enable_resource_monitors ? var.resource_monitors : {}

  name = "${local.base_prefix}_${upper(each.key)}_MONITOR"
  
  credit_quota    = each.value.credit_quota
  frequency       = each.value.frequency
  start_timestamp = each.value.start_timestamp != "" ? each.value.start_timestamp : null
  end_timestamp   = each.value.end_timestamp != "" ? each.value.end_timestamp : null
  
  # Notification thresholds
  notify_triggers = each.value.notify_triggers
  
  # Notification settings
  notify_users = each.value.notify_users
}
