# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

locals {
  resource_group_name          = "${lower(var.resource_group_name)}-${lower(random_string.suffix.result)}"
  tags                         = merge(
    var.tags,
    map(
      "suffix",                  random_string.suffix.result,
      "workspace",               terraform.workspace,
    )
  )
}

# Create Azure resource group to be used for VDC resources
resource azurerm_resource_group governance_rg {
  name                         = local.resource_group_name
  location                     = var.location

  tags                         = local.tags
}

module auto_shutdown {
  source                       = "./modules/functions"
  resource_group_id            = azurerm_resource_group.governance_rg.id
  location                     = azurerm_resource_group.governance_rg.location
  tags                         = local.tags
}