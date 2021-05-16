data azurerm_subscription primary {}

resource azurerm_log_analytics_workspace vcd_workspace {
  name                         = "${var.resource_group_name}-loganalytics"
  location                     = var.workspace_location
  resource_group_name          = var.resource_group_name
  sku                          = "pergb2018"
  retention_in_days            = 90 

  tags                         = var.tags
}

resource azurerm_log_analytics_solution solution {
  solution_name                = each.value
  location                     = var.workspace_location
  resource_group_name          = var.resource_group_name
  workspace_resource_id        = azurerm_log_analytics_workspace.vcd_workspace.id
  workspace_name               = azurerm_log_analytics_workspace.vcd_workspace.name

  plan {
    publisher                  = "Microsoft"
    product                    = "OMSGallery/${each.value}"
  }

  for_each                     = toset(var.solutions)
} 

resource azurerm_monitor_diagnostic_setting activity_log {
  name                         = "${var.resource_group_name}-activity-log"
  target_resource_id           = data.azurerm_subscription.primary.id
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.vcd_workspace.id

  log {
    category                   = "Administrative"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }

  log {
    category                   = "Security"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }

  log {
    category                   = "ServiceHealth"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }

  log {
    category                   = "Alert"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }

  log {
    category                   = "Recommendation"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }

  log {
    category                   = "Policy"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }

  log {
    category                   = "Autoscale"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }

  log {
    category                   = "ResourceHealth"
    enabled                    = true
    retention_policy {
      enabled                  = false
    }
  }
}
