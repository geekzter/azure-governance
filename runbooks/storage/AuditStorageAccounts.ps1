<# 
.SYNOPSIS 
    Validates storage accounts (e.g. no anonymous access)
 
.DESCRIPTION 
    This Azure Automation runbook connects to Azure subscriptions and validates storage accounts

    PRE-REQUISITES
    1. An Automation connection asset called "AzureRunAsConnection" that contains the information for authenticating with Azure. 
    2. Storage Account Contributor or higher permissions on the subscriptions accessed

.PARAMETER subscriptionGuids
    Optional
    The subscriptions GUID's to check storage accounts for
    Use JSON syntax, when supplied in the Azure Portal e.g. ["2b1e7654-5177-4f35-8574-d272bf83acc6", "fd1f5ca3-b0fc-491f-a932-f11fd6f7f923"]
    If not specified, all subscription the Rnas connection has access to will be checked

.OUTPUTS
    Returns strings with status messages

.EXAMPLE
    Use these Azure Automation runbook parameters in the Azure portal
    Subscriptions: ["2b1e7654-5177-4f35-8574-d272bf83acc6", "fd1f5ca3-b0fc-491f-a932-f11fd6f7f923"]
    ResourceGroupNames: ["Automation","ITGS-Governance"]
    TargetSize: Standard_D8s_v3
    ScaleDirectionisUp: No Value
    
.NOTES 
    AUTHOR: Eric van Wijk 
    LASTEDIT: 2017-12-18
    DISCLAIMER: This script is provided as-is. The author is not committed to support this script. No guarantees on (future) operation or compatibility can be given. 
    It should be tailored to the environment it will run in. The script may need to be updated as API's and capabilities change.
    
    Requires Azure PowerShell modules 4.0 or above

    Azure Automation
    https://docs.microsoft.com/en-us/azure/automation/automation-intro

    Azure Storage Security
    https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide
    https://docs.microsoft.com/en-us/azure/storage/blobs/storage-manage-access-to-resources
#> 
 
# Returns strings with status messages 
[OutputType([String])] 

param  
( 
   [parameter(Mandatory=$false,HelpMessage="The GUID's of the subscriptions to check")]
   [String[]] $subscriptionGuids
) 

# Instrumentation
#$global:errorPreference = "Continue"
#$global:warningPreference = "Continue"
#$global:informationPreference = "Continue"
#$global:verbosePreference = "SilentlyContinue"
#$global:debugPreference = "SilentlyContinue"
$maxBlobsToList = 64

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
    
    $storageAccounts = Get-AzureRmStorageAccount 
    foreach ($storageAccount in $storageAccounts)
    {
        Write-Verbose "`nProcessing storage account with Id $($storageAccount.Id) ..."     
        # Create anonymous context, as we want to test anonynous access (being rejected)
        # $anonymousContext = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -Anonymous
        $storageKey = Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -AccountName $storageAccount.StorageAccountName
        $storageContext = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey.Value[0]
        $storageContainers = Get-AzureStorageContainer -Context $storageContext

        foreach ($storageContainer in $storageContainers)
        {
            Write-Verbose "`nProcessing storage container with name $($storageContainer.Name) ..."     
            if ($storageContainer.PublicAccess -ne "Off")
            {
                # TODO: Audit event
                Write-Warning "`nStorage container with name $($storageContainer.Name) has not turned off public access! `
Subscription Name: $subscriptionName `
Subscription Id  : $subscriptionGuid `
Resource Group   : $($storageAccount.ResourceGroupName) `
Storage Account  : $($storageAccount.StorageAccountName) `
Storage Container: $($storageContainer.Name) `
Public Access    : $($storageContainer.PublicAccess)"

                # List the offending blobs
                $blobs = Get-AzureStorageBlob -Container $storageContainer.Name -Context $storageContext -MaxCount $maxBlobsToList
                if ($verbosePreference -eq "Continue")
                {
                    $blobs
                }
                foreach ($blob in $blobs) {
                    Write-Warning "Unprotected blob $($blob.ICloudBlob.uri.AbsoluteUri) in $($storageAccount.Id)"
                }

                if ($blobs.Length > $maxBlobsToList)
                {
                    Write-Warning "More than $maxBlobsToList unprotected blob found in $($storageAccount.Id), only first $maxBlobsToList are listed"
                }
            }

            # TODO: Files


            # TODO: Tables
        }
    }
}