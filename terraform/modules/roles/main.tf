data azurerm_subscription primary {}

resource azurerm_role_definition delegated_contributor {
  name                         = "Delegated Contributor"
  scope                        = data.azurerm_subscription.primary.id
  description                  = "This is a custom role created via Terraform"

  permissions {
    actions                    = ["*"]
    not_actions                = [
        # Access Control
        "Microsoft.Authorization/*/write",

        # Disks
        "Microsoft.Compute/disks/delete",

        # Virtual Machines
        "Microsoft.Compute/virtualMachines/*/action",
        "Microsoft.Compute/virtualMachines/delete",
        "Microsoft.Compute/virtualMachines/write",

        # Key Vaults
        "Microsoft.KeyVault/locations/deletedVaults/purge/action",

        # Networking
        "Microsoft.Network/expressRouteCircuits/*",
        "Microsoft.Network/networkSecurityGroups/delete",
        "Microsoft.Network/networkSecurityGroups/write",
        "Microsoft.Network/publicIPAddresses/write",
        "Microsoft.Network/routeTables/write",
        "Microsoft.Network/virtualNetworks/delete",
        "Microsoft.Network/virtualNetworks/write",
        "Microsoft.Network/vpnGateways/*",
        "Microsoft.Network/vpnSites/*",

        # Storage Accounts
        "Microsoft.Storage/storageAccounts/delete",
        "Microsoft.Storage/storageAccounts/listkeys/action",
        "Microsoft.Storage/storageAccounts/regeneratekey/action",
        "Microsoft.Storage/storageAccounts/write",
    ]
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}

resource null_resource delegated_contributor_json {
    triggers                   = {
        always                 = timestamp()
    }
    provisioner local-exec {
        command                = "az role definition list -n '${azurerm_role_definition.delegated_contributor.name}' --custom-role-only --scope ${azurerm_role_definition.delegated_contributor.scope} --subscription ${data.azurerm_subscription.primary.subscription_id} --query '[0]'"
    }
}