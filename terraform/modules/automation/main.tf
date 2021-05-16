resource azurerm_automation_account automation {
  name                         = "${var.resource_group_name}-automation"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku_name                     = "Basic"

  tags                         = var.tags
}

resource azurerm_log_analytics_linked_service automation {
  resource_group_name          = var.resource_group_name
  workspace_id                 = var.workspace_id
  read_access_id               = azurerm_automation_account.automation.id

  tags                         = var.tags
}