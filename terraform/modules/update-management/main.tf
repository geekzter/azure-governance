locals {
  update_time                  = "${formatdate("YYYY-MM-DD",timestamp())}T${var.update_time}:00+00:00"
}

resource azurerm_resource_group_template_deployment linux_updates {
  name                         = "${var.resource_group_name}-linux-updates"
  resource_group_name          = var.resource_group_name
  deployment_mode              = "Incremental"
  parameters_content           = jsonencode({
    automationAccountName      = {
      value                    = var.automation_account_name
    }
    interval                   = {
      value                    = 1
    }
    operatingSystem            = {
      value                    = "Linux"
    }
    scheduleName               = {
      value                    = "${var.resource_group_name}-linux-update-schedule"
    }
    scope                      = {
      value                    = [var.scope_id]
    }
    startTime                  = {
      value                    = local.update_time
    }
    timeZone                   = {
      value                    = var.timezone
    }
  })
  template_content             = file("${path.root}/../arm/update-management-linux.json")

  tags                         = var.tags
}
resource azurerm_resource_group_template_deployment windows_updates {
  name                         = "${var.resource_group_name}-windows-updates"
  resource_group_name          = var.resource_group_name
  deployment_mode              = "Incremental"
  parameters_content           = jsonencode({
    automationAccountName      = {
      value                    = var.automation_account_name
    }
    interval                   = {
      value                    = 1
    }
    operatingSystem            = {
      value                    = "Windows"
    }
    scheduleName               = {
      value                    = "${var.resource_group_name}-windows-update-schedule"
    }
    scope                      = {
      value                    = [var.scope_id]
    }
    startTime                  = {
      value                    = local.update_time
    }
    timeZone                   = {
      value                    = var.timezone
    }
  })
  template_content             = file("${path.root}/../arm/update-management-windows.json")

  tags                         = var.tags
}