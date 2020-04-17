data azurerm_subscription primary {}

resource azurerm_security_center_workspace workspace {
  scope                        = data.azurerm_subscription.primary.id
  workspace_id                 = var.workspace_id
}

resource azurerm_security_center_subscription_pricing sku {
  tier                         = var.sku
}