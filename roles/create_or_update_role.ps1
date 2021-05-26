#!/usr/bin/env pwsh
param ( 
  [parameter(Mandatory=$false)][string]$SubscriptionID=$env:ARM_SUBSCRIPTION_ID,
  [parameter(Mandatory=$false)][string]$RoleDefinitionFile="application-owner.jsonc"
) 
#Requires -Version 7

. (Join-Path $PSScriptRoot .. scripts functions.ps1)

AzLogin -DisplayMessages

$roleObject = (Get-Content $RoleDefinitionFile | ConvertFrom-Json)  
if ($SubscriptionID) {
  Write-Verbose "Subscription: $SubscriptionID"
  $roleObject.assignableScopes = ($roleObject.assignableScopes -replace "00000000-0000-0000-0000-000000000000",$SubscriptionID)
} elseif ($roleObject.assignableScopes -match "00000000-0000-0000-0000-000000000000") {
  Write-Warning "No SubscriptionID specified, exiting"
  exit
}

$updatedroleDefinitionFile = New-TemporaryFile
Write-Verbose "role:`n$($roleObject | ConvertTo-Json -Depth 4)"
$roleObject | ConvertTo-Json -Depth 4 | Out-File $updatedroleDefinitionFile

Write-Debug "Applying role definition file ${updatedroleDefinitionFile}:`n"
Write-Debug "$(Get-Content $updatedroleDefinitionFile)"

$roleExists = $(az role definition list --query "[?roleName=='$($roleObject.roleName)']" -o tsv)
if ($roleExists) {
  Write-Host "Role $($roleObject.name) already exists, updating..."
  az role definition update --role-definition $updatedroleDefinitionFile --subscription $SubscriptionID
} else {
  Write-Host "Creating role $($roleObject.name)..."
  az role definition create --role-definition $updatedroleDefinitionFile --subscription $SubscriptionID
}
