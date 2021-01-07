terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 1.1.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.41"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
  }
  required_version = "~> 0.13.0"
}

# Microsoft Azure Resource Manager Provider
provider azurerm {
  alias = "defaults"
  features {
    virtual_machine {
      # Don't accidentally delete data on local disks
      delete_os_disk_on_deletion = false
    }
  }
}
data azurerm_subscription default {
  provider = azurerm.defaults
}
provider azuread {
  tenant_id = var.tenant_id != null && var.tenant_id != "" ? var.tenant_id : data.azurerm_subscription.default.tenant_id
}
provider azurerm {
  features {
    template_deployment {
      delete_nested_items_during_deletion = true
    }
  }
  subscription_id = var.subscription_id != null && var.subscription_id != "" ? var.subscription_id : data.azurerm_subscription.default.subscription_id
  tenant_id       = var.tenant_id != null && var.tenant_id != "" ? var.tenant_id : data.azurerm_subscription.default.tenant_id
}
data azurerm_subscription primary {}