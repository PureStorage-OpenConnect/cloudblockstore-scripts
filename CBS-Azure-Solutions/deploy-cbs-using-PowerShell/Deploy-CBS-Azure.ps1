param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the SubscriptionId where your Resource Group is located")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript(
        { $null -ne (Get-AzSubscription -SubscriptionId $_ -WarningAction silentlyContinue) },
        ErrorMessage = "Subscription  was not found in tenant {0} . Please verify that the subscription exists in this tenant."
    )]         
    [string]
    $subscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Enter the region where your Resource group is located")]
    [ValidateNotNullOrEmpty()]
    [string]
    $region,

    [Parameter(Mandatory = $true, HelpMessage = "Enter zone")]
    [ValidateNotNullOrEmpty()]
    [string]
    $zone,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $arrayName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $orgDomain,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [securestring]
    $licenseKey,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $applicationResourceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsVersion, 


    [Parameter(Mandatory = $true, HelpMessage = "cbsModel v10 or v20")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('(V10MUR1|V20MUR1)')] 
    [string]
    $cbsModel,

    [Parameter(Mandatory = $true, HelpMessage = "Enter your Virtual Network name")]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsVNETName,

    [Parameter(Mandatory = $true, HelpMessage = "Enter your System Subnet name")]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsSystemSubentName,

    [Parameter(Mandatory = $true, HelpMessage = "Enter your Management Subnet name")]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsMngmtSubentName,

    [Parameter(Mandatory = $true, HelpMessage = "Enter your iSCSI Subnet name")]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsiSCSiSubentName,

    [Parameter(Mandatory = $true, HelpMessage = "Enter your Replication Subnet name")]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsReplicaSubentName
)

# Hardcoded template file url
$templateFile = "https://raw.githubusercontent.com/PureStorage-OpenConnect/cloudblockstore-scripts/main/CBS-Azure-Solutions/deploy-cbs-using-PowerShell/template.json"


## Connect to Azure Account
# Connect-AzAccount

# Select validated subscription 
Set-AzContext -Subscription $subscriptionId -WarningAction silentlyContinue | Out-Null
# Resource_Group
$resourceGroup = (Get-AzVirtualNetwork -Name $cbsVNETName).ResourceGroupName
if ($null -eq $resourceGroup) {
    Write-Host "Caution: No virtual network found by the name '$cbsVNETName'"
    Exit
}

$PSvnet = Get-AzVirtualNetwork -Name $cbsVNETName
$PSSubnet = Get-AzVirtualNetworkSubnetConfig -Name $cbsSystemSubentName -VirtualNetwork $PSvnet
if ($null -eq $PSSubnet) {
    Write-Host "Caution: No subnet found by the name '$cbsSystemSubentName'"
    Exit
}

New-AzResourceGroupDeployment `
    -Name $applicationResourceName `
    -ResourceGroupName $resourceGroup `
    -TemplateUri $templateUri `
    -applicationResourceName $applicationResourceName `
    -arrayName $arrayName `
    -sku $cbsModel `
    -zone $zone `
    -licenseKey $licenseKey `
    -replicationResourceGroup $resourceGroup `
    -systemResourceGroup $resourceGroup `
    -managementResourceGroup $resourceGroup `
    -iSCSIResourceGroup $resourceGroup `
    -managementVnet $cbsVNETName `
    -systemVnet $cbsVNETName `
    -iSCSIVnet $cbsVNETName `
    -replicationVnet $cbsVNETName `
    -systemSubnet $cbsSystemSubentName `
    -iSCSISubnet $cbsiSCSiSubentName `
    -replicationSubnet $cbsReplicaSubentName `
    -managementSubnet $cbsMngmtSubentName `
    -alertRecipients $alertRecipients `
    -orgDomain $orgDomain





