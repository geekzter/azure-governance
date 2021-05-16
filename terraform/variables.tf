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
variable security_center_auto_provision {
  default      = false
  type         = bool
}
variable security_center_contact_email {
  default      = ""
}
variable security_center_sku {
  default      = "Standard"
}

variable subscription_id {
  type         = string
  default      = ""
}
variable log_analytics_solutions {
  type         = list
  default      = [
    "Security",
    "SecurityCenterFree",
    "ServiceMap",
    "Updates",
    "VMInsights",
  ]
} 
variable tenant_id {
  type         = string
  default      = ""
}

variable timezone {
  default                      = "W. Europe Standard Time"
}
variable update_time {
  default      = "21:00"
}