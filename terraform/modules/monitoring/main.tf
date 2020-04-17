resource azurerm_log_analytics_workspace vcd_workspace {
  name                         = "${var.resource_group_name}-loganalytics"
  location                     = var.workspace_location
  resource_group_name          = var.resource_group_name
  sku                          = "Standalone"
  retention_in_days            = 90 

  tags                         = var.tags
}
