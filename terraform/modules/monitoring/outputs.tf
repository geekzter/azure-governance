  output workspace_resource_id {
    value                      = azurerm_log_analytics_workspace.vcd_workspace.id
  }
  output workspace_key {
    sensitive                  = true
    value                      = azurerm_log_analytics_workspace.vcd_workspace.primary_shared_key
  }
  output workspace_id {
    value                      = azurerm_log_analytics_workspace.vcd_workspace.workspace_id
  }
