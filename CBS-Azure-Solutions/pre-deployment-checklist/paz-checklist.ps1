<#
    paz-checklist.ps1 -
    Version:        3.0.6
    Author:         Vaclav Jirovsky, Adam Mazouz, David Stamen @ Pure Storage
.SYNOPSIS
    Checking if the prerequisites required for deploying Cloud Block Store are met before create the array on Azure.
.DESCRIPTION
    This script will validate and verify the following:
	- Check if the region where VNET is created is supported for CBS deployments.
	- Check if the region has enough Ebdsv5 or DSv3 Family vCPU to deploy Cloud Block Store.
	- Check if the System Subnet has outbound internet Access.
    - Check if the Signed In User has the required Azure Role Assignment.
.INPUTS
    - Azure Subscription Id.
    - Pure Cloud Block Store Model (V20MUR1, V10MUR1, V10MP2R2, V20MP2R2).
    - Azure Virtual Network, where CBS subnets are located.
    - Azure Subnet, designated for CBS System subnet.
    - (optional) Tags to be assigned for a temporary VM created for connectivity test
.OUTPUTS
    Print out the on console the validation results.
.EXAMPLE
    Option 1: Use Azure Cloud Shell to paste the script and run it
        & paz-checklist.ps1
    Option 2: Or use your local machine to install Azure Powershell Module and make sure to login to Azure first
        Connect-AzAccount
.CHANGELOG
    10/24/24  3.0.6 Disable Storage Account Creation for Boot Diagnostics
    8/30/2024 3.0.5 Bug Fixes for V10MP2R2
    7/15/2024 3.0.4 Updated Region Support, V10MP2R2
    7/11/2024 3.0.3 Added Microsoft.Storage Endpoint, Fixed naming of the LB
    6/6/2024  3.0.2 Added ability to modify VM Size and VM OS types
    3/15/2024 3.0.1 Improved test for outbound connectivity (to deploy a test load balancer)
    3/12/2024 3.0.0 Script refactored, to provide a full report of the readiness of the environment for CBS deployment
    26/1/2024 2.0.1 Adding V20MP2R2 and PremiumV2 SSD support to the script
#>
<#
.DISCLAIMER
The sample script and documentation are provided AS IS and are not supported by the author or the author's employer, unless otherwise agreed in writing. You bear all risk relating to the use or performance of the sample script and documentation.
The author and the author's employer disclaim all express or implied warranties (including, without limitation, any warranties of merchantability, title, infringement 	or fitness for a particular purpose). In no event shall the author, the author's employer or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever arising out of the use or performance of the sample script and 	documentation (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss), even if 	such person has been advised of the possibility of such damages.
#>
param (
  [Parameter(Mandatory = $true, HelpMessage = 'Enter the SubscriptionId where your Resource Group is located')]
  [ValidateNotNullOrEmpty()]
  [ValidateScript(
    { $null -ne (Get-AzSubscription -SubscriptionId $_ -WarningAction silentlyContinue) },
    ErrorMessage = 'Subscription  was not found in tenant {0} . Please verify that the subscription exists in this tenant.'
  )]
  [string]
  $subscriptionId,

  [Parameter(Mandatory = $true, HelpMessage = 'Enter CBS Model (V10MUR1, V20MUR1, V10MP2R2, V20MP2R2)')]
  [ValidateNotNullOrEmpty()]
  [ValidateSet('V10MUR1', 'V20MUR1', 'V10MP2R2', 'V20MP2R2')]
  [string]
  $cbsModel,

  [Parameter(Mandatory = $true, HelpMessage = 'Enter your vNET name')]
  [ValidateNotNullOrEmpty()]
  [string]
  $cbsVNETName,

  [Parameter(Mandatory = $false, HelpMessage = "Enter your subnet name within vNET used for 'system'")]
  [ValidateNotNullOrEmpty()]
  [string]
  $vnetSystemSubnetName = 'system',

  [Parameter(Mandatory = $false, HelpMessage = 'Enter name for temporary VM created for connectivity tests')]
  [ValidateNotNullOrEmpty()]
  [string]
  $tempVmName = 'CBS_PreCheck_TempVM',

  [Parameter(Mandatory = $false, HelpMessage = "List of tags to be assigned to the temporary VM created for connectivity tests, required by your Azure landing zone (e.g. @{'tag1'='value1';'tag2'='value2'})")]
  [hashtable]
  $tempVmTags = @{},

  [Parameter(Mandatory = $false, HelpMessage = 'VM Size to be Used. Defaults to Standard_B1s')]
  $tempVmSize = 'Standard_B1s',

  [Parameter(Mandatory = $false, HelpMessage = 'VM Operating System to be Used. Choices, Suse, Ubuntu, Redhat. Defaults to Ubuntu')]
  $tempVmOS = 'Ubuntu'
)

$finalReportOutput = @()

$AcceptableOS = @('Ubuntu', 'RedHat', 'Suse')
if ($tempVmOS -in $AcceptableOS) {

} else {
  Write-Error 'Unknown VM Operating System selected. Please select one of the following: Ubuntu, Suse, Redhat';
  Exit
}


if ($cbsModel -eq 'V10MP2R2' -or $cbsModel -eq 'V20MP2R2') {
  $supportedRegions =
  'australiaeast',
  'brazilsouth',
  'canadacentral',
  'centralindia',
  'centralus',
  'eastasia',
  'eastus',
  'eastus2',
  'francecentral',
  'germanywestcentral',
  'israelcentral',
  'italynorth',
  'japaneast',
  'koreacentral',
  'mexicocentral',
  'northeurope',
  'norwayeast',
  'polandcentral',
  'southafricanorth',
  'southcentralus',
  'southeastasia',
  'spaincentral',
  'swedencentral',
  'switzerlandnorth',
  'uaenorth',
  'uksouth',
  'westeurope',
  'westus2',
  'westus3'
} elseif ($cbsModel -eq 'V10MUR1' -or $cbsModel -eq 'V20MUR1') {
  $supportedRegions =
  'australiacentral',
  'australiaeast',
  'brazilsouth',
  'brazilsoutheast',
  'canadacentral',
  'canadaeast',
  'centralindia',
  'centralus',
  'eastasia',
  'eastus',
  'eastus2',
  'francecentral',
  'germanywestcentral',
  'italynorth',
  'japaneast',
  'koreacentral',
  'koreasouth',
  'northcentralus',
  'northeurope'
  'polandcentral',
  'qatarcentral',
  'southafricanorth',
  'southcentralus',
  'southeastasia',
  'swedencentral',
  'switzerlandnorth',
  'uaenorth',
  'uksouth',
  'ukwest',
  'westeurope',
  'westus',
  'westus2',
  'westus3'
} else {
  Write-Error 'Unknown CBS Model selected. Please select one of the following: V10MUR1, V20MUR1, V10MP2R2, V20MP2R2';
  Exit
}

$CLI_VERSION = '3.0.6'

Write-Host -ForegroundColor DarkRed -BackgroundColor Black @"
 _____                   _____ _
|  __ \                 / ____| |
| |__) |   _ _ __ ___  | (___ | |_ ___  _ __ __ _  __ _  ___
|  ___/ | | | '__/ _ \  \___ \| __/ _ \| '__/ _`  |/ _`  |/ _ \
| |   | |_| | | |  __/  ____) | || (_) | | | (_| | (_| |  __/
|_|    \__,_|_|  \___| |_____/ \__\___/|_|  \__,_|\__, |\___|
                                                   __/ /
"@

Write-Host  @"
------------------------------------------------------------
    Pure Cloud Block Store - Pre-Deployment Check Report
                (c) 2024 Pure Storage
                        v$CLI_VERSION
------------------------------------------------------------
"@

try {


  # Select validated subscription
  Select-AzSubscription -SubscriptionId $subscriptionId -WarningAction silentlyContinue | Out-Null

  $PSStyle.Progress.View = 'Classic'
  $endpointsToTest =
  'rest.cloud-support.purestorage.com',
  'ra.cloud-support.purestorage.com',
  'restricted-rest.cloud-support.purestorage.com',
  'restricted-ra.cloud-support.purestorage.com',
  'rest.cloud-support.purestorage.com',
  'rest2.cloud-support.purestorage.com',
  'management.azure.com',
  'cosmos.azure.com'

  # Resource_Group
  Write-Progress 'Checking vNET presence' -PercentComplete 0

  $rg = (Get-AzVirtualNetwork -Name $cbsVNETName).ResourceGroupName
  if ($null -eq $rg) {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'vNET existence'
      Result   = 'FAILED'
      Details  = "vNET '$cbsVNETName' WAS NOT found"
    };

    Exit
  }
  Write-Progress 'Checking vNET presence' -PercentComplete 100

  $finalReportOutput += [pscustomobject]@{
    TestName = 'vNET existence'
    Result   = 'OK'
    Details  = "vNET '$cbsVNETName' was found in RG '$rg'"
  };

  Write-Progress 'Checking subnet presence' -PercentComplete 0

  $PSvnet = Get-AzVirtualNetwork -Name $cbsVNETName
  $PSSubnet = Get-AzVirtualNetworkSubnetConfig -Name $vnetSystemSubnetName -VirtualNetwork $PSvnet
  if ($null -eq $PSSubnet) {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Subnet existence'
      Result   = 'FAILED'
      Details  = "Subnet '$vnetSystemSubnetName' WAS NOT found"
    };
    Exit
  }

  $finalReportOutput += [pscustomobject]@{
    TestName = 'Subnet existence'
    Result   = 'OK'
    Details  = "Subnet '$vnetSystemSubnetName' was found"
  };

  Write-Progress 'Checking subnet presence' -PercentComplete 100

  Write-Progress 'Checking region support' -PercentComplete 0
  # REGION
  $region = (Get-AzVirtualNetwork -Name  $cbsVNETName).Location

  ###################
  ## Region Supported ##
  ###################
  if ($region -in $supportedRegions) {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Region support'
      Result   = 'OK'
      Details  = "Region '$region' is declared as supported for deploying a $cbsModel"
    };
  } else {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Region support'
      Result   = 'FAILED'
      Details  = "Region '$region' IS declared as NOT supported for deploying a $cbsModel"
    };
  }

  Write-Progress 'Checking region support' -PercentComplete 100
  Write-Progress 'Checking vCPU limits' -PercentComplete 0

  ###################
  ##  vCPU Limits  ##
  ###################

  $cbsVCPU = switch ($cbsModel) {
    'V10MUR1' { 64 }
    'V20MUR1' { 128 }
    'V10MP2R2' { 32 }
    'V20MP2R2' { 64 }
    Default { Write-Host 'Invalid CBS Model selected.'; exit }
  }

  $vmSize = switch ($cbsModel) {
    'V10MUR1' { 'Standard_D32s_v3' }
    'V20MUR1' { 'Standard_D64s_v3' }
    'V10MP2R2' { 'Standard_E16bds_v5' }
    'V20MP2R2' { 'Standard_E32bds_v5' }
    Default { Write-Host 'Invalid CBS Model selected.'; exit }
  }

  $diskType = switch ($cbsModel) {
    'V10MUR1' { 'UltraSSD_LRS' }
    'V20MUR1' { 'UltraSSD_LRS' }
    'V10MP2R2' { 'PremiumV2_LRS' }
    'V20MP2R2' { 'PremiumV2_LRS' }
    Default { Write-Host 'Invalid CBS Model selected.'; exit }
  }

  $VMFamily = (Get-AzComputeResourceSku -Location $region | Where-Object ResourceType -EQ 'virtualMachines' | Select-Object Name, Family | Where-Object Name -EQ $vmSize | Select-Object -Property Family).Family

  $currentLimit = Get-AzVMUsage -Location $region | Where-Object { $_.Name.Value -eq $VMFamily } | Select-Object -ExpandProperty CurrentValue
  Write-Progress 'Checking vCPU limits' -PercentComplete 50
  $limit = Get-AzVMUsage -Location $region | Where-Object { $_.Name.Value -eq $VMFamily } | Select-Object -ExpandProperty Limit

  $vCPUAfterDeploy = $limit - ($cbsVCPU + $currentLimit)
  if (($cbsVCPU + $currentLimit) -le $limit) {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'vCPUs availability (quota)'
      Result   = 'OK'
      Details  = "There is enough $vmSize vCPUs for deploying a $cbsModel ($vCPUAfterDeploy after deployment, currently used $currentLimit, total limit $limit)"
    };
  } else {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'vCPUs availability (quota)'
      Result   = 'FAILED'
      Details  = "There IS NOT enough $vmSize vCPUs for deploying a $cbsModel ($vCPUAfterDeploy after deployment, currently used $currentLimit, total limit $limit)"
    };

    exit;
  }
  Write-Progress 'Checking vCPU limits' -PercentComplete 100

  ###################
  ## Backend Azure Disk Availability ##
  ###################

  Write-Progress 'Checking Managed Disk availability' -PercentComplete 0
  $zones = Get-AzComputeResourceSku | Where-Object {
    $_.ResourceType -eq 'disks' -and $_.Name -eq $diskType -and $_.Locations -eq $region
  } | Select-Object -ExpandProperty LocationInfo | Select-Object -ExpandProperty Zones

  if ($zones) {

    $finalReportOutput += [pscustomobject]@{
      TestName = 'Managed Disks availability'
      Result   = 'OK'
      Details  = "The disk SKU '$diskType' is available in region '$region' in availability zones '$zones' for deploying a $cbsModel"
    };
  } else {

    $finalReportOutput += [pscustomobject]@{
      TestName = 'Managed Disks availability'
      Result   = 'FAILED'
      Details  = "The disk SKU '$diskType' is NOT available in region '$region' for deploying a $cbsModel"
    };
  }

  Write-Progress 'Checking Managed Disk availability' -PercentComplete 100

  ####################
  ## Service Endpoint ##
  ####################

  Write-Progress 'Checking Service Endpoints' -PercentComplete 0

  $ServiceEndpoints = (Get-AzVirtualNetworkSubnetConfig -Name $vnetSystemSubnetName -VirtualNetwork $PSvnet).ServiceEndpoints
  if ($ServiceEndpoints.Service -eq 'Microsoft.AzureCosmosDB') {

    $finalReportOutput += [pscustomobject]@{
      TestName = 'Azure CosmosDB Service Endpoint'
      Result   = 'OK'
      Details  = "The service endpoint for CosmosDB is attached to the System Subnet '$vnetSystemSubnetName'"
    };
  } else {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Azure CosmosDB Service Endpoint'
      Result   = 'FAILED'
      Details  = "The service endpoint for CosmosDB is NOT attached to the System Subnet '$vnetSystemSubnetName'"
    };
  }

  Write-Progress 'Checking Service Endpoints' -PercentComplete 40

  if ($ServiceEndpoints.Service -eq 'Microsoft.KeyVault') {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Azure Key Vault Service Endpoint'
      Result   = 'OK'
      Details  = "The service endpoint for KeyVault is attached to the System Subnet '$vnetSystemSubnetName'"
    };
  } else {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Azure KeyVault Service Endpoint'
      Result   = 'FAILED'
      Details  = "The service endpoint for KeyVault is NOT attached to the System Subnet '$vnetSystemSubnetName'"
    };
  }

  Write-Progress 'Checking Service Endpoints' -PercentComplete 65

  if ($ServiceEndpoints.Service -eq 'Microsoft.Storage') {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Azure Storage Service Endpoint'
      Result   = 'OK'
      Details  = "The service endpoint for Storage is attached to the System Subnet '$vnetSystemSubnetName'"
    };
  } else {
    $finalReportOutput += [pscustomobject]@{
      TestName = 'Azure Storage Service Endpoint'
      Result   = 'FAILED'
      Details  = "The service endpoint for Storage is NOT attached to the System Subnet '$vnetSystemSubnetName'"
    };
  }

  Write-Progress 'Checking Service Endpoints' -PercentComplete 100

  ####################
  ## Azure IAM Roles ##
  ####################
  Write-Progress 'Checking IAM Role' -PercentComplete 0
  $currentSignInName = (Get-AzContext).Account.Id
  $listOfAssignedRoles = Get-AzRoleAssignment -SignInName $currentSignInName -ExpandPrincipalGroups | Where-Object Scope -EQ "/subscriptions/$subscriptionId"
  $collections = $listOfAssignedRoles.RoleDefinitionName
  if ($listOfAssignedRoles) {
    if ($collections -like 'Contributor' -or $collections -like 'Owner' -or $collections -like 'Managed Application Contributor Role') {
      $finalReportOutput += [pscustomobject]@{
        TestName = 'Azure IAM Role'
        Result   = 'OK'
        Details  = 'Signed user has at least one of the required role assigned to the subscription'
      };
    } else {
      $finalReportOutput += [pscustomobject]@{
        TestName = 'Azure IAM Role'
        Result   = 'FAILED'
        Details  = "Signed user DOESN'T have any of the required role (Managed Application Contributor/Contributor/Owner) assigned to the subscription"
      };
    }
  }

  Write-Progress 'Checking IAM Role' -PercentComplete 100

  ####################
  ## Connectivity Test ##
  ####################

  # 1/ Create Test_VM in System Subnet
  ####################

  $region = (Get-AzVirtualNetwork -Name  $cbsVNETName).Location

  Write-Progress 'Creating a temporary test loadbalancer in System subnet' -PercentComplete 0

  $backendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name myBackendPool
  $frontendIP = New-AzLoadBalancerFrontendIpConfig -Name myFrontendIP -Subnet $PSSubnet
  $lbRule = New-AzLoadBalancerRuleConfig -Name myLoadBalancerRule -FrontendIpConfiguration $frontendIP -BackendAddressPool $backendPool -Protocol Tcp -FrontendPort 80 -BackendPort 80

  Write-Progress 'Creating a temporary test loadbalancer in System subnet' -PercentComplete 50

  $loadBalancer = New-AzLoadBalancer -ResourceGroupName $rg -Name "$TempVMName-LB" -Location $region -FrontendIpConfiguration $frontendIP -LoadBalancingRule $lbRule -BackendAddressPool $backendPool -Sku 'Standard'

  $bepool = $loadBalancer.BackendAddressPools[0]
  Write-Progress 'Creating a temporary test loadbalancer in System subnet' -PercentComplete 100

  Write-Progress 'Creating a temporary test VM in System subnet' -PercentComplete 0
  ## Define a credential object to store the username and password for the virtual machine
  $UserName = 'azureuser'
  $Password = ConvertTo-SecureString ( -Join ('ABCDabcd&@#$%1234'.tochararray() | Get-Random -Count 10 | ForEach-Object { [char]$_ })) -AsPlainText -Force
  $psCred = New-Object System.Management.Automation.PSCredential($UserName, $Password)

  $NetworkSG = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $region -Name "$tempVMName-NSG" -Force
  $NIC = New-AzNetworkInterface -Name "$tempVMName-NIC" -ResourceGroupName $rg -Location $region -Subnet $PSSubnet -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $NetworkSG -Force

  Write-Progress 'Creating a temporary test VM in System subnet' -PercentComplete 50

  try {
    ## Set the VM Size and Type
    $VirtualMachine = New-AzVMConfig -VMName $tempVMName -VMSize $tempVmSize -Tags $tempVmTags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName testvm -Credential $psCred
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
  } catch {
    Write-Host 'An error occurred:'
    Write-Host $_
    exit
  }
  try {
    ## Set the VM Source Image
    if ($tempVmOS -eq 'Ubuntu') {
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '18_04-lts-gen2' -Version 'latest'
    } elseif ($tempVmOS -eq 'Suse') {
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'suse' -Offer 'sles-12-sp5-basic' -Skus 'gen2' -Version 'latest'
    } elseif ($tempVmOS -eq 'Redhat') {
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'redhat' -Offer 'RHEL' -Skus '87-gen2' -Version 'latest'
    }

    New-AzVM -ResourceGroupName $rg -Location $region -VM $VirtualMachine -WarningAction silentlyContinue | Out-Null
    Set-AzVMExtension -ResourceGroupName $rg -Location $region -VMName $tempVMName -Name 'NetworkWatcherAgentLinux' -ExtensionType 'NetworkWatcherAgentLinux' -Publisher 'Microsoft.Azure.NetworkWatcher' -TypeHandlerVersion '1.4' | Out-Null
    # 2/ Wait for the VM to be created
    ####################
    $VMStatus = (Get-AzVM -Name $tempVMName -ResourceGroupName $rg -Status).Statuses[1].DisplayStatus
    while ($VMStatus -ne 'VM running' ) {
      Write-Progress 'Creating a temporary test VM in System subnet' -PercentComplete 75
      Start-Sleep -Seconds 10
    }
  } catch {
    Write-Host 'An error occurred:'
    Write-Host $_
    exit
  }

  Write-Progress 'Creating a temporary test VM in System subnet' -PercentComplete 100

  # 3/ Run Command against the Test_VM
  ####################
  Write-Progress 'Testing endpoints connectivity (approx. 5 mins)' -Status 'waiting...' -PercentComplete 0

  $VM1 = Get-AzVM -ResourceGroupName $rg | Where-Object -Property Name -EQ $tempVMName
  Write-Progress 'Testing endpoints connectivity (approx. 5 mins)' -Status 'starting...' -PercentComplete 0

  $networkWatcher = Get-AzNetworkWatcher | Where-Object -Property Location -EQ -Value $VM1.Location

  Write-Progress 'Testing endpoints connectivity (approx. 5 mins)' -Status 'started' -PercentComplete 10

  $i = 0;
  foreach ($endpoint in $endpointsToTest) {
    Write-Progress 'Testing endpoints connectivity (approx. 5 mins)' -CurrentOperation $endpoint -PercentComplete (($i + 1) * 100 / $endpointsToTest.Count)

    $TestConnectionStatus = (Test-AzNetworkWatcherConnectivity -NetworkWatcher $networkWatcher -SourceId $VM1.id -DestinationAddress $endpoint -DestinationPort 443).ConnectionStatus
    if ($TestConnectionStatus -eq 'Reachable') {
      $finalReportOutput += [pscustomobject]@{
        TestName = "$endpoint connection"
        Result   = 'OK'
        Details  = "Connection over HTTPS (port 443) has been succesfully established to $endpoint"
      };
    } else {
      $finalReportOutput += [pscustomobject]@{
        TestName = "$endpoint connection"
        Result   = 'FAILED'
        Details  = "Connection over HTTPS (port 443) has NOT been succesfully established to $endpoint"
      };
    }

    $i++;
  }

  Write-Progress 'Testing endpoints connectivity (approx. 5 mins)' -PercentComplete 100

  # 4/ Remove the Test_VM
  Write-Progress 'Removing the temporary test VM' -PercentComplete 0
  $vm = Get-AzVM -Name $tempVMName -ResourceGroupName $rg

    $diskName = $vm.StorageProfile.OsDisk.Name
    $null = $vm | Remove-AzVM -Force
    Write-Progress "Removing the temporary test VM" -PercentComplete 25
    Remove-AzNetworkInterface -Name "$tempVMName-NIC" -ResourceGroupName $rg -Force
    Write-Progress "Removing the temporary test VM" -PercentComplete 50
    Remove-AzDisk -ResourceGroupName $rg -DiskName $diskName -Force  | Out-Null
    Write-Progress "Removing the temporary test VM" -PercentComplete 75
    Remove-AzNetworkSecurityGroup -ResourceGroupName $rg -Name "$tempVMName-NSG" -Force
    Write-Progress "Removing the temporary test VM" -PercentComplete 100
    Write-Progress "Removing the temporary load balancer" -PercentComplete 0
    Remove-AzLoadBalancer -ResourceGroupName $rg -Name "$TempVMName-LB" -Force
    Write-Progress "Removing the temporary load balancer" -PercentComplete 100
}

finally {
    Write-Output ""
    Write-Output "-----------------------------------------------------"
    Write-Output "                   Final Report                      "
    write-Output "-----------------------------------------------------"

    Write-Output $finalReportOutput | Format-Table @{
        Label      = 'TestName'
        Expression =
        {
            switch ($_.TestName) {
                { $_ } { $color = "$($PSStyle.Foreground.FromRGB(255,255,49))" }
            }
            "$color$($_.TestName)$($PSStyle.Reset)"
        }
    },
    @{
        Label      = 'Result'
        Expression =
        {
            switch ($_.Result) {
                { $_ -eq "OK" } { $color = "$($PSStyle.Foreground.Green)" }
                { $_ -ne "OK" } { $color = "$($PSStyle.Foreground.Red)$($PSStyle.Blink)" }
            }
            "$color$($_.Result)$($PSStyle.Reset)"
        }

    },
    @{
        Label      = 'Details'
        Expression =
        {
            "$color$($_.Details)$($PSStyle.Reset)"
        }

    }
}
