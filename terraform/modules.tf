module auto_shutdown {
  source                       = "./modules/functions"
  resource_group_id            = azurerm_resource_group.governance_rg.id
  location                     = azurerm_resource_group.governance_rg.location
  tags                         = local.tags

  count                        = var.deploy_functions ? 1 : 0
}

module monitoring {
  source                       = "./modules/monitoring"
  resource_group_name          = azurerm_resource_group.governance_rg.name
  location                     = azurerm_resource_group.governance_rg.location
  solutions                    = var.log_analytics_solutions
  workspace_location           = azurerm_resource_group.governance_rg.location
  tags                         = local.tags
}

module automation {
  source                       = "./modules/automation"
  resource_group_name          = azurerm_resource_group.governance_rg.name
  location                     = azurerm_resource_group.governance_rg.location
  workspace_id                 = module.monitoring.workspace_resource_id
  tags                         = local.tags
}

module update_management {
  source                       = "./modules/update-management"
  automation_account_name      = module.automation.automation_account_name
  resource_group_name          = azurerm_resource_group.governance_rg.name
  scope_id                     = data.azurerm_subscription.primary.id
  timezone                     = var.timezone
  update_time                  = var.update_time
  tags                         = local.tags

  depends_on                   = [module.automation]
}

module roles {
  source                       = "./modules/roles"

  count                        = var.deploy_custom_roles ? 1 : 0
}

module security_center {
  source                       = "./modules/security-center"
  auto_provision               = var.security_center_auto_provision
  contact_email                = var.security_center_contact_email
  sku                          = var.security_center_sku
  workspace_id                 = module.monitoring.workspace_resource_id

  depends_on                   = [module.monitoring]
}