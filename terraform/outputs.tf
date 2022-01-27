  output workspace_resource_id {
    value                      = module.monitoring.workspace_resource_id
  }
  output workspace_id {
    value                      = module.monitoring.workspace_id
  }
  output workspace_key {
    sensitive                  = true
    value                      = module.monitoring.workspace_key
  }
