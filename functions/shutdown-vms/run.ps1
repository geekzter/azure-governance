# Input bindings are passed in via param block
param($Timer)

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time
Write-Host "Starting Shutdown script at UTC $((Get-Date).ToUniversalTime())"

$vmsToStop = Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines" -TagName shutdown -TagValue true

# Stopping VM's (async)
$vmsToStop | ForEach-Object {
    Write-Host "Stopping $($_.Name)..."
    $null = Stop-AzVM -Id $_.ResourceId -NoWait -Force
}

# Wait for VM's to be stopped
$vmsToStop | ForEach-Object {
    Write-Host "Waiting for $($_.Name) to stop..."
    $null = Stop-AzVM -Id $_.ResourceId -Force
}

# Write an information log with the current time
Write-Host "Finished Shutdown script at UTC $((Get-Date).ToUniversalTime())"
