variable deploy_custom_roles {
  type         = bool
  default      = false
}

variable deploy_functions {
  type         = bool
  default      = false
}

variable location {
  description  = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default      = "westeurope"
}
variable resource_group_prefix {
  description  = "The name of the resource group to be used"
  default      = "Governance"
}
variable subscription_id {
  type         = string
  default      = ""
}
variable tenant_id {
  type         = string
  default      = ""
}
