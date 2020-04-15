variable resource_group_id {
  description                  = "The id of the resource group"
}
variable location {
  description                  = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable tags {
  description                  = "A map of the tags to use for the resources that are deployed"
  type                         = map
} 
