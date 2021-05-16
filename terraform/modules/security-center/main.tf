data azurerm_subscription primary {}

resource azurerm_security_center_workspace workspace {
  scope                        = data.azurerm_subscription.primary.id
  workspace_id                 = var.workspace_id
}

resource azurerm_security_center_contact contact {
  email                        = var.contact_email

  alert_notifications          = true
  alerts_to_admins             = true

  count                        = var.contact_email != "" ? 1 : 0
}

resource azurerm_security_center_subscription_pricing sku {
  tier                         = var.sku
}

resource azurerm_security_center_auto_provisioning provisioning {
  auto_provision               = var.auto_provision ? "On" : "Off"
}