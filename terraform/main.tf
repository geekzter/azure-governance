data azurerm_client_config current {}

# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

locals {
  resource_group_name          = "${lower(var.resource_group_prefix)}-${lower(random_string.suffix.result)}"
  suffix                       = random_string.suffix.result
  tags                         = {
    application                = "Governance"
    provisioner                = "terraform"
    provisioner-client-id      = data.azurerm_client_config.current.client_id
    provisioner-object-id      = data.azurerm_client_config.current.object_id
    repository                 = "azure-governance"
    suffix                     = local.suffix
    workspace                  = terraform.workspace
  }
}

# Create Azure resource group to be used for VDC resources
resource azurerm_resource_group governance_rg {
  name                         = local.resource_group_name
  location                     = var.location

  tags                         = local.tags
}

resource azurerm_storage_account config {
  name                         = "governancecfg${local.suffix}"
  resource_group_name          = azurerm_resource_group.governance_rg.name
  location                     = azurerm_resource_group.governance_rg.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"

  blob_properties {
    delete_retention_policy {
      days                     = 365
    }
  }

  tags                         = local.tags
}
resource azurerm_storage_container configuration {
  name                         = "configuration"
  storage_account_name         = azurerm_storage_account.config.name
  container_access_type        = "private"
}
resource azurerm_storage_blob minecraft_auto_vars_configuration {
  name                         = "config.auto.tfvars"
  storage_account_name         = azurerm_storage_account.config.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source                       = "${path.root}/config.auto.tfvars"

  count                        = fileexists("${path.root}/config.auto.tfvars") ? 1 : 0
}
resource azurerm_storage_blob minecraft_workspace_vars_configuration {
  name                         = "${terraform.workspace}.tfvars"
  storage_account_name         = azurerm_storage_account.config.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source                       = "${path.root}/${terraform.workspace}.tfvars"

  count                        = fileexists("${path.root}/${terraform.workspace}.tfvars") ? 1 : 0
}