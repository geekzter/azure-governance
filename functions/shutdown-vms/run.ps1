# Input bindings are passed in via param block
param($Timer)

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time
Write-Host "Starting Shutdown script at UTC $((Get-Date).ToUniversalTime())"

# Get resources using Resource Graph (works accross subscriptions), ignore VM's with tag 'shutdown' value 'never'
$graphQuery = "Resources | where type =~ 'Microsoft.Compute/virtualMachines' | where tags.shutdown!='never' | project id, name | order by name asc"
$vmsToStop = Search-AzGraph -Query $graphQuery

# Stopping VM's (async)
$vmsToStop | ForEach-Object {
    Write-Host "Stopping $($_.name)..."
    $null = Stop-AzVM -Id $_.id -NoWait -Force
}

# Wait for VM's to be stopped
$vmsToStop | ForEach-Object {
    Write-Host "Waiting for $($_.name) to stop..."
    $null = Stop-AzVM -Id $_.id -Force
}

# Write an information log with the current time
Write-Host "Finished Shutdown script at UTC $((Get-Date).ToUniversalTime())"
