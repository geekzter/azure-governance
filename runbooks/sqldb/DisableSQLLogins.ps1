<# 
.SYNOPSIS 
    Disables SQL Logins (e.g. no anonymous access)
 
.DESCRIPTION 
    This Azure Automation runbook connects to Azure subscriptions and validates storage accounts

    PRE-REQUISITES
    1. An Automation connection asset called "AzureRunAsConnection" that contains the information for authenticating with Azure. 
    2. Storage Account Contributor or higher permissions on the subscriptions accessed

.PARAMETER subscriptionGuids
    Optional
    The subscriptions GUID's to check SQL Servers for
    Use JSON syntax, when supplied in the Azure Portal e.g. ["2b1e7654-5177-4f35-8574-d272bf83acc6", "fd1f5ca3-b0fc-491f-a932-f11fd6f7f923"]
    If not specified, all subscription the Rnas connection has access to will be checked

.OUTPUTS
    Returns strings with status messages

.EXAMPLE
    Use these Azure Automation runbook parameters in the Azure portal
    Subscriptions: ["2b1e7654-5177-4f35-8574-d272bf83acc6", "fd1f5ca3-b0fc-491f-a932-f11fd6f7f923"]
    ResourceGroupName: ["CRAPAAS"]
    
.NOTES 
    AUTHOR: Eric van Wijk 
    LASTEDIT: 2018-12-9
    DISCLAIMER: This script is provided as-is. The author is not committed to support this script. No guarantees on (future) operation or compatibility can be given. 
    It should be tailored to the environment it will run in. The script may need to be updated as API's and capabilities change.
    
    Requires Azure PowerShell modules 5.0 or above

    Azure Automation
    https://docs.microsoft.com/en-us/azure/automation/automation-intro

#> 
 
# Returns strings with status messages 
[OutputType([String])] 

param  
( 
   [parameter(Mandatory=$false,HelpMessage="The GUID's of the subscriptions to check")]
   [String[]] $subscriptionGuids,
   [parameter(Mandatory=$false,HelpMessage="The name of the resource group to check")]
   [String] $resourceGroupName
) 

# Instrumentation
#$global:errorPreference = "Continue"
#$global:warningPreference = "Continue"
#$global:informationPreference = "Continue"
$global:verbosePreference = "Continue"
#$global:debugPreference = "SilentlyContinue"

# Prepare Azure connection
$connectionAssetName = "AzureRunAsConnection" 
$conn = Get-AutomationConnection -Name $connectionAssetName 
if ($conn -eq $null) 
{ 
    throw "Could not retrieve connection asset: $connectionAssetName. Assure that this asset exists in the Automation account." 
} 
$account = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationId $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -ErrorAction Stop 
if ($verbosePreference -eq "Continue")
{
    $account
}

# Determine subscriptions
if ($subscriptionGuids -eq $null)
{
    # No subscriptions provided, so let's enumerate the ones available
    # Only enumerate the ones connected to the corporate AAD tenant
    Write-Verbose "`nRetrieving subscriptions for tenant $($conn.TenantID)" 
    $subscriptionGuids = Get-AzureRmSubscription -TenantId $conn.TenantID | Select-Object -Expand Id
}

# Enumerate subscriptions
foreach ($subscriptionGuid in $subscriptionGuids)
{
    $subscriptionContext = Set-AzureRmContext -SubscriptionId $subscriptionGuid
    # $subscriptionContext =  Get-AzureRmContext 
    if ($verbosePreference -eq "Continue")
    {
        $subscriptionContext
    }

    if ($subscriptionContext.SubscriptionName -ne $null)
    {
        $subscriptionName = $subscriptionContext.SubscriptionName
    }
    else
    {
        $subscriptionName = $subscriptionContext.Name
    }
    Write-Verbose "`nProcessing subscription $subscriptionName with Id $subscriptionGuid ..." 
    
    if ($resourceGroupName -eq $null) {
        $sqlServers = Get-AzureRmSqlServer 
    }
    else {
        $sqlServers = Get-AzureRmSqlServer -ResourceGroupName $resourceGroupName
    }

    foreach ($sqlServer in $sqlServers)
    {
        Write-Verbose "`nProcessing SQL Server with name $($sqlServer.ServerName) ..."    
        # Reset password
        $serverPassword = [guid]::NewGuid().ToString()
        $secureString = ConvertTo-SecureString $serverPassword -AsPlainText -Force
        Set-AzureRmSqlServer -ResourceGroupName $sqlServer.ResourceGroupName -ServerName $sqlServer.ServerName -SqlAdministratorPassword $secureString -ServerVersion $sqlServer.ServerVersion

        # Define the connection to the SQL Database
        # $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$($sqlServer.FullyQualifiedDomainName),1433;User ID=$($sqlServer.SqlAdministratorLogin);Password=$($serverPassword);Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")

        # Add outbound IP address to SQL Firewall
        $ipAddress = Invoke-WebRequest 'https://api.ipify.org' -UseBasicParsing | Select-Object -ExpandProperty Content
        Write-Verbose "`nOutbound IP address is $ipAddress" 

        $currentRules = Get-AzureRmSqlServerFirewallRule -ServerName $sqlServer.ServerName -ResourceGroupName $sqlServer.ResourceGroupName
        $rule = $currentRules | Where-Object ($_.StartIpAddress -eq $ipAddress)
        # If a rule with this IP does not exist
        If (!$rule)
        {
            Write-Host No rule for $ipAddress - creating
            New-AzureRmSqlServerFirewallRule -ResourceGroupName $sqlServer.ResourceGroupName -ServerName $sqlServer.ServerName -StartIpAddress $ipAddress -EndIpAddress $ipAddress -FirewallRuleName "RunbookRule $ipAddress"
        }

        # Fetch SQL script
        Invoke-WebRequest "https://raw.githubusercontent.com/geekzter/azure-governance/master/runbooks/sqldb/DisableSQLLogins.sql" -UseBasicParsing -OutFile DisableSQLLoginsFetched.sql

        $params = @{
            'Database' = 'master'
            'ServerInstance' = $sqlServer.FullyQualifiedDomainName
            'Username' = $sqlServer.SqlAdministratorLogin
            'Password' = $serverPassword
            'OutputSqlErrors' = $true
            'InputFile' = ".\DisableSQLLoginsFetched.sql"
        }
        Invoke-Sqlcmd @params
    }
}