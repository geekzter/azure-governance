# See https://www.terraform.io/docs/backends/types/azurerm.html

terraform {
  backend "azurerm" {
    # Use partial configuration, as we do not want to expose these details in source control
    resource_group_name        = "automation"
    #storage_account_name       = "tfbackend"
    #container_name             = "governance" 
    key                        = "terraform.tfstate"
  }
}