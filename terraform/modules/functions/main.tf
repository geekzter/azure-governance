locals {
  # Last element of resource id is resource name
  resource_group_name          = element(split("/",var.resource_group_id),length(split("/",var.resource_group_id))-1)
}

data azurerm_client_config current {}
data azurerm_subscription primary {}

resource azurerm_storage_account automation_storage {
  name                         = "${lower(replace(local.resource_group_name,"-",""))}automation"
  location                     = var.location
  resource_group_name          = local.resource_group_name
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  enable_https_traffic_only    = true

  tags                         = var.tags
}

resource azurerm_advanced_threat_protection automation_storage {
  target_resource_id           = azurerm_storage_account.automation_storage.id
  enabled                      = true
}

resource azurerm_app_service_plan vdc_functions {
  name                         = "${local.resource_group_name}-functions-plan"
  location                     = var.location
  resource_group_name          = local.resource_group_name
  kind                         = "FunctionApp"

  sku {
    tier                       = "Dynamic"
    size                       = "Y1"
  }

  tags                         = var.tags
}

resource azurerm_function_app vdc_functions {
  name                         = "${local.resource_group_name}-functions"
  location                     = var.location
  resource_group_name          = local.resource_group_name
  app_service_plan_id          = azurerm_app_service_plan.vdc_functions.id
  storage_connection_string    = azurerm_storage_account.automation_storage.primary_connection_string
  enable_builtin_logging       = "true"

  identity {
    type                       = "SystemAssigned"
  }

  version                      = "~2" # Required for PowerShell (Core)

  tags                         = var.tags
}

# # Grant functions access required
# resource azurerm_role_definition vm_stop_start {
# # role_definition_id           = "00000000-0000-0000-0000-000000000000"
#   name                         = "Virtual Machine Operator (Custom ${local.resource_group_name})"
#   scope                        = data.azurerm_subscription.primary.id

#   permissions {
#     actions                    = [
#         "Microsoft.Compute/*/read",
#         "Microsoft.Compute/virtualMachines/start/action",
#         "Microsoft.Compute/virtualMachines/restart/action",
#         "Microsoft.Compute/virtualMachines/deallocate/action"
#         ]
#     not_actions                = []
#   }

#   assignable_scopes            = [data.azurerm_subscription.primary.id]
# }

resource azurerm_role_assignment vm_stop_start {
# name                         = "00000000-0000-0000-0000-000000000000"
  scope                        = data.azurerm_subscription.primary.id
# role_definition_id           = azurerm_role_definition.vm_stop_start.id
  role_definition_name         = "Virtual Machine Contributor"
  principal_id                 = azurerm_function_app.vdc_functions.identity.0.principal_id
}

resource azurerm_role_assignment sql_access {
# name                         = "00000000-0000-0000-0000-000000000000"
  scope                        = data.azurerm_subscription.primary.id
  role_definition_name         = "SQL Server Contributor"
  principal_id                 = azurerm_function_app.vdc_functions.identity.0.principal_id
}

# Configure function resources with ARM template as Terraform doesn't (yet) support this
# https://docs.microsoft.com/en-us/azure/templates/microsoft.web/2018-11-01/sites/functions
resource azurerm_template_deployment vdc_shutdown_function_arm {
  name                         = "${local.resource_group_name}-shutdown-function-arm"
  resource_group_name          = local.resource_group_name
  deployment_mode              = "Incremental"

  template_body                = file("${path.module}/automation-functions.json")

  parameters                   = {
    functionsAppServiceName    = azurerm_function_app.vdc_functions.name
    disableSqlLoginName        = "disable-sql-logins"
    disableSqlLoginFile        = file("../functions/disable-sql-logins/run.ps1")
    disableSqlLoginScript      = file("../functions/disable-sql-logins/disable-sql-logins.sql")
    shutdownName               = "shutdown-vms"
    shutdownFile               = file("../functions/shutdown-vms/run.ps1")
    functionSchedule           = "0 0 23 * * *" # Every night at 23:00
    requirementsFile           = file("../functions/requirements.psd1")
    profileFile                = file("../functions/profile.ps1")
    hostFile                   = file("../functions/host.json")
    proxiesFile                = file("../functions/proxies.json")
  }

  depends_on                   = [azurerm_function_app.vdc_functions] # Explicit dependency for ARM templates
}