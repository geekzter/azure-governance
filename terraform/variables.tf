variable location {
  description                  = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default                      = "westeurope"
}
variable resource_group_name {
  description                  = "The name of the resource group to be used"
  default                      = "Governance"
}
variable tags {
  description = "A map of the tags to use for the resources that are deployed"
  type                         = map

  default = {
    application                = "Governance"
    provisioner                = "terraform"
  }
} 