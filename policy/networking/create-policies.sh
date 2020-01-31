#!/bin/sh
# az policy definition create --name 'audit-nsg-inbound-internet' --display-name 'Audit Internet in NSG rule source address' --description 'This policy audits Internet in NSG rule source' --rules './audit-nsg-inbound-internet.json' --mode All
# az policy assignment create --name 'ITGS-VDC-audit-nsg-inbound-internet' --scope <scope> --policy "audit-nsg-inbound-internet"
az policy definition create --name 'audit-network-azure-sqldb' --display-name 'Audit All Azure in SQL Firewall rule source' --description 'This policy audits All Azure in NSG rule source' --rules './audit-network-azure-sqldb.json' --mode All
az policy definition create --name 'audit-network-internet-sqldb' --display-name 'Audit Internet in SQL Firewall rule source' --description 'This policy audits Internet in NSG rule source' --rules './audit-network-internet-sqldb.json' --mode All
