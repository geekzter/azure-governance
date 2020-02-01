# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

Write-Host "`nRetrieving subscriptions..." 
$subscriptionGuids = Get-AzureRmSubscription | Select-Object -Expand Id

# Enumerate subscriptions
foreach ($subscriptionGuid in $subscriptionGuids)
{
    $subscriptionContext = Set-AzContext -SubscriptionId $subscriptionGuid
    if ($verbosePreference -eq "Continue")
    {
        $subscriptionContext
    }

    if ($subscriptionContext.SubscriptionName)
    {
        $subscriptionName = $subscriptionContext.SubscriptionName
    }
    else
    {
        $subscriptionName = $subscriptionContext.Name
    }
    Write-Host "`nProcessing subscription $subscriptionName with Id $subscriptionGuid ..." 

    $sqlServers = Get-AzSqlServer 
    # Enumerate SQL Servers
    foreach ($sqlServer in $sqlServers)
    {
        Write-Host "`nProcessing SQL Server with name $($sqlServer.ServerName) ..."    
        # Reset password
        $serverPassword = [guid]::NewGuid().ToString()
        $secureString = ConvertTo-SecureString $serverPassword -AsPlainText -Force
        Set-AzSqlServer -ResourceGroupName $sqlServer.ResourceGroupName -ServerName $sqlServer.ServerName -SqlAdministratorPassword $secureString -ServerVersion $sqlServer.ServerVersion

        # Define the connection to the SQL Database
        # $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$($sqlServer.FullyQualifiedDomainName),1433;User ID=$($sqlServer.SqlAdministratorLogin);Password=$($serverPassword);Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")

        # Add outbound IP address to SQL Firewall
        $ipAddress = Invoke-WebRequest 'https://api.ipify.org' -UseBasicParsing | Select-Object -ExpandProperty Content
        Write-Host "`nOutbound IP address is $ipAddress" 

        $currentRules = Get-AzServerFirewallRule -ServerName $sqlServer.ServerName -ResourceGroupName $sqlServer.ResourceGroupName
        $rule = $currentRules | Where-Object ($_.StartIpAddress -eq $ipAddress)
        # If a rule with this IP does not exist
        If (!$rule)
        {
            Write-Host "No rule for $ipAddress, creating...""
            New-AzSqlServerFirewallRule -ResourceGroupName $sqlServer.ResourceGroupName -ServerName $sqlServer.ServerName -StartIpAddress $ipAddress -EndIpAddress $ipAddress -FirewallRuleName "RunbookRule $ipAddress"
        }

        # Fetch SQL script
        Invoke-WebRequest "https://raw.githubusercontent.com/geekzter/azure-governance/master/runbooks/sqldb/DisableSQLLogins.sql" -UseBasicParsing -OutFile DisableSQLLoginsFetched.sql

        $params = @{
            'Database' = 'master'
            'ServerInstance' = $sqlServer.FullyQualifiedDomainName
            'Username' = $sqlServer.SqlAdministratorLogin
            'Password' = $serverPassword
            'OutputSqlErrors' = $true
            #'InputFile' = ".\DisableSQLLoginsFetched.sql"
            'InputFile' = "./disable-sql-logins.sql"
        }
        Invoke-Sqlcmd @params
    }
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
