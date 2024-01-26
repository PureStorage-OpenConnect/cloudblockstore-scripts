<#
  paz-checklist.ps1 - 
  Version:        2.0.0
  Author:         Adam Mazouz @ Pure Storage
.SYNOPSIS
    Checking if the prerequisites required for deploying Cloud Block Store are met before create the array on Azure.
.DESCRIPTION
  This script will validate and verify the following: 
	  - Check if the region where VNET is created is supported for CBS deployments. 
	  - Check if the region has enough Ebdsv5 or DSv3 Family vCPU to deploy Cloud Block Store.
	  - Check if the Ultra Disks are available and in which Availability Zone. 
	  - Check if the System Subnet has outbound internet Access.
      - Check if the Signed In User has the required Azure Role Assignment.
.INPUTS
      - Azure Subscription Id.
      - Pure Cloud Block Store Model (V20UR1, V10UR1, V20P2R2).
      - Azure Virtual Network, where CBS subnets are located. 
      - Azure Subnet, designated for CBS System subnet. 
.OUTPUTS
    Print out the on console the validation results. 
.EXAMPLE
    Option 1: Use Azure CloudShell to paste the script and run it
        & paz-checklist.ps1
    Option 2: Or use your local machine to install Azure Powershell Module and make sure to login to Azure first
        Connect-AzAccount
.CHANGELOG
    26/1/2024 2.0.1 Adding V20P2R2 and PremiumV2 SSD support to the script
#>
<#
.DISCLAIMER
The sample script and documentation are provided AS IS and are not supported by the author or the author's employer, unless otherwise agreed in writing. You bear all risk relating to the use or performance of the sample script and documentation. 
The author and the author's employer disclaim all express or implied warranties (including, without limitation, any warranties of merchantability, title, infringement 	or fitness for a particular purpose). In no event shall the author, the author's employer or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever arising out of the use or performance of the sample script and 	documentation (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss), even if 	such person has been advised of the possibility of such damages.
#>
param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the SubscriptionId where your Resource Group is located")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript(
        { $null -ne (Get-AzSubscription -SubscriptionId $_ -WarningAction silentlyContinue) },
        ErrorMessage = "Subscription  was not found in tenant {0} . Please verify that the subscription exists in this tenant."
    )]         
    [string]
    $subscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Enter CBS Model (V10U, V20U, V20P)")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('(V10U|V20U|V20P)')] 
    [string]
    $cbsModel,

    [Parameter(Mandatory = $true, HelpMessage = "Enter your Virtual Network name")]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsVNETName,

    [Parameter(Mandatory = $true, HelpMessage = "Enter your System Subnet name")]
    [ValidateNotNullOrEmpty()]
    [string]
    $cbsSystemSubentName
) 


# Select validated subscription 
Select-AzSubscription -SubscriptionId $subscriptionId -WarningAction silentlyContinue | Out-Null

# Assign a tmp test vm name
$testVMName = "CBS_PreDeploy_Checklist_VM_Temp"


# Resource_Group
$rg = (Get-AzVirtualNetwork -Name $cbsVNETName).ResourceGroupName
if ($null -eq $rg) {
    Write-Host "Caution: No virtual network found by the name '$cbsVNETName'."
    Exit
}

$PSvnet = Get-AzVirtualNetwork -Name $cbsVNETName
$PSSubnet = Get-AzVirtualNetworkSubnetConfig -Name $cbsSystemSubentName -VirtualNetwork $PSvnet
if ($null -eq $PSSubnet) {
    Write-Host "Caution: No subnet found by the name '$cbsSystemSubentName'"
    Exit
}

# REGION
$region = (Get-AzVirtualNetwork -Name  $cbsVNETName).Location

###################
## Region Supported ## 
###################
Write-Output "." 
Write-Output "." 
Write-Output "."
Write-Output "# --------------------------------------------------"
Write-Output "Checking if the region is supported to deploy Cloud Block Store" 
Write-Output "." 
Write-Output "." 
Write-Output "."
if ($cbsModel -eq "V20P") {
    $supportedRegions = "centralus", "eastus", "eastus2", "southcentralus", "westus3", "westus2", "canadacentral", "northeurope", "westeurope", "uksouth", "francecentral", "switzerlandnorth", "swedencentral", "southeastasia", "japaneast", "australiaeast", "koreacentral" , "brazilsouth", "uaenorth", "centralindia", "southafricanorth", "norwayeast", "eastasia"
    ($region -in $supportedRegions) ? (Write-Host "$region region is supported" -ForegroundColor Green) : (Write-Host "!!!! $region region is NOT supported !!!!" -ForegroundColor Red)    
} elseif ($cbsModel -eq "V20U" -or $cbsModel -eq "V10U"){ 
    $supportedRegions = "centralus", "eastus", "eastus2", "southcentralus", "northcentralus", "westus3", 
    "westus2", "westus", "northeurope", "westeurope", "uksouth", "francecentral", 
    "switzerlandnorth", "swedencentral", "southeastasia", "germanywestcentral", "japaneast", "australiaeast", 
    "koreacentral" , "brazilsouth", "uaenorth", "centralindia", "southafricanorth",  
    "qatarcentral", "eastasia", "australiacentral", "koreasouth"
    ($region -in $supportedRegions) ? (Write-Host "$region region is supported" -ForegroundColor Green) : (Write-Host "!!!! $region region is NOT supported !!!!" -ForegroundColor Red)  
}


###################
## vCPU Limits ## 
###################
Write-Output "# --------------------------------------------------"
Write-Output "Checking if the region has enough vCPU to deploy Cloud Block Store ... " 
Write-Output "." 
Write-Output "." 
Write-Output "." 
$cbsVCPU = switch ($cbsModel) {
    "V10U" { 32 }
    "V20U" { 64 }
    "V20P" { 32 }
    Default { Write-Host "Invalid CBS Model selected."; exit }
}

if ($cbsModel -eq "V20P") {
    $currentLimit = az vm list-usage --location $region --query "[?name.localizedValue=='Standard EBDSv5 Family vCPUs'].currentValue" -o tsv
    $limit =  az vm list-usage --location $region --query "[?name.localizedValue=='Standard EBDSv5 Family vCPUs'].limit" -o tsv
    Write-Host $limit, $currentLimit
    $vCPUAfterDeploy = $limit - ($cbsVCPU + $currentLimit)
    ($cbsVCPU + $currentLimit) -le $limit ? (Write-Host "There is enough Ebds_v5 vCPU for deploying $cbsModel" -ForegroundColor Green && Write-Host "Number of availible vCPU after deploying $cbsModel is:" -NoNewline && Write-Host "$vCPUAfterDeploy" -ForegroundColor Green ) : (Write-Host "!!!! NO enough Ebds_v5 vCPU for deploying $cbsModel !!!!" -ForegroundColor Red) 
} elseif ($cbsModel -eq "V20U" -or $cbsModel -eq "V10U") {
    $currentLimit = az vm list-usage --location $region --query "[?name.localizedValue=='Standard DSv3 Family vCPUs'].currentValue" -o tsv
    $limit =  az vm list-usage --location $region --query "[?name.localizedValue=='Standard DSv3 Family vCPUs'].limit" -o tsv
    $vCPUAfterDeploy = $limit - ($cbsVCPU + $currentLimit)
    ($cbsVCPU + $currentLimit) -le $limit ? (Write-Host "There is enough Ds_v3 vCPU for deploying $cbsModel" -ForegroundColor Green && Write-Host "Number of availible vCPU after deploying $cbsModel is:" -NoNewline && Write-Host "$vCPUAfterDeploy" -ForegroundColor Green ) : (Write-Host "!!!! NO enough DSv3 vCPU for deploying $cbsModel !!!!" -ForegroundColor Red) 
}





###################
## Backend Azure Disk Availability ## 
###################
Write-Output "." 
Write-Output "." 
Write-Output "."
Write-Output "# --------------------------------------------------"
Write-Host "Checking if the Backend Managed Disks available ..." 
Write-Output "." 
Write-Output "." 
Write-Output "." 
$vmSize = switch ($cbsModel) {
    "V10U" { "Standard_D32s_v3" }
    "V20U" { "Standard_D64s_v3" }
    "V20P" { "Standard_E32bds_v5" }
    Default { Write-Host "Invalid CBS Model selected."; exit }
}
if ($cbsModel -eq "V20P") {
    $zones = Get-AzComputeResourceSku | Where-Object {
        $_.ResourceType -eq "disks" -and 
        $_.Name -eq "PremiumV2_LRS" -and 
        $_.Location -eq $region
    } | Select-Object -ExpandProperty LocationInfo | Select-Object -ExpandProperty Zones

    if ($zones) { 
        Write-host "$vmSize is supported with PremiumV2 Disk in $region region, and it is supported in: " -ForegroundColor Green
    } else { 
        Write-host "!!!! PremiumV2 Disk are NOT availible in $region region" -ForegroundColor Red
    }
    if($sku) {
        foreach ($zoneCollection in $zones) {
            foreach ($zone in $zoneCollection) {
            Write-Host "   - Availiblity Zone $zone" -ForegroundColor Green
            }
        }       
    } 
} elseif ($cbsModel -eq "V20U" -or $cbsModel -eq "V10U") {
    $zones = Get-AzComputeResourceSku | Where-Object {
        $_.ResourceType -eq "disks" -and 
        $_.Name -eq "UltraSSD_LRS" -and 
        $_.Location -eq $region
    } | Select-Object -ExpandProperty LocationInfo | Select-Object -ExpandProperty Zones

    if ($zones) { 
        Write-host "$vmSize is supported with Ultra Disk in $region region, and it is supported in: " -ForegroundColor Green
    } else { 
        Write-host "!!!! Ultra Disk are NOT availible in $region region" -ForegroundColor Red
    }
    if($sku) {
        foreach ($zoneCollection in $zones) {
            foreach ($zone in $zoneCollection) {
            Write-Host "   - Availiblity Zone $zone" -ForegroundColor Green
            }
        }       
    }
}

####################
## Service Endpoint ## 
####################
Write-Output "# --------------------------------------------------"
Write-Output "Checking if the System Subnet has Service Endpoint attached ..." 
Write-Output "." 
Write-Output "." 
Write-Output "." 
$ServiceEndpoints = (Get-AzVirtualNetworkSubnetConfig -Name $cbsSystemSubentName -VirtualNetwork $PSvnet).ServiceEndpoints
if ($ServiceEndpoints.Service -eq "Microsoft.AzureCosmosDB") {
    Write-Host "AzureCosmosDB Service Endpoint is attached" -ForegroundColor Green
} else {
    Write-Host "!!!! No AzureCosmosDB Service Endpoint attaeched to System Subnet" -ForegroundColor Red
}
if ($ServiceEndpoints.Service -eq "Microsoft.KeyVault") {
    Write-Host "KeyVault Service Endpoint is attached" -ForegroundColor Green
} else {
    Write-Host "!!!! No KeyVault Service Endpoint attaeched to System Subnet" -ForegroundColor Red
} 



####################
## Azure IAM Roles ## 
####################
Write-Output "# --------------------------------------------------"
Write-Output "Checking if the SignInUser has the required Azure Role Assignment for the selected subscription ..." 
Write-Output "." 
Write-Output "." 
Write-Output "." 
$currentSignInName = (Get-AzContext).Account.Id
$listOfAssignedRoles = Get-AzRoleAssignment -Scope /subscriptions/$subscriptionId | Where-Object -Property SignInName -EQ $currentSignInName
$collections = $listOfAssignedRoles.RoleDefinitionName 
if($listOfAssignedRoles) {
    if ($collections -like "Contributor" -or $collections -like "Owner" -or $collections -like "Managed Application Contributor Role") {
        Write-Host "--> You have at least one of the required role assignment: $collections" -ForegroundColor Green
    } else { 
        Write-Host "!!! You DO NOT have the required role assignment to deploy CBS !!!!" -ForegroundColor Red
    }
}


####################
## Test Conncetivity ## 
####################
Write-Output "# --------------------------------------------------"
Write-Output "Checking if the System Subnet has outbound internet Access..." 
Write-Output "Creating the test VM in the System Subnet..." 
Write-Output "." 
Write-Output "." 
Write-Output "." 
# 1/ Create Test_VM in System Subnet
####################
## Define a credential object to store the username and password for the virtual machine
$UserName = "azureuser"
$Password = ConvertTo-SecureString "Passw0rd" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($UserName, $Password)

## Create a virtual network card and associate it with the public IP address
# $SecurityGroupRule = New-AzNetworkSecurityRuleConfig -Name "HTTPS-Rule" -Description "Allow HTTPS" -Access "Allow" -Protocol "TCP" -Direction "Outbound" -Priority 100 -DestinationPortRange 443 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" 
## Create a network security group

# $NetworkSG = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $region -Name Test_VM_NSG -SecurityRules $SecurityGroupRule
$NetworkSG = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $region -Name "$testVMName-NSG" 
$NIC = New-AzNetworkInterface -Name "$testVMName-NIC" -ResourceGroupName $rg -Location $region -Subnet $PSSubnet -NetworkSecurityGroup $NetworkSG 

## Create a virtual network card and associate it with the public IP address without NSG
# $NIC = New-AzNetworkInterface -Name Test_VM_NIC -ResourceGroupName $rg -Location $region -Subnet $PSSubnet


## Set the VM Size and Type
$VirtualMachine = New-AzVMConfig -VMName $testVMName -VMSize Standard_B1s 
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName testvm -Credential $psCred 
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id

try {
    ## Set the VM Source Image
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '18_04-lts-gen2' -Version "latest"
# New-AzVM -ResourceGroupName $rg -Location $region -VM $VirtualMachine -GenerateSshKey -SshKeyName TestVMSSHKey -WarningAction silentlyContinue | Out-Null
New-AzVM -ResourceGroupName $rg -Location $region -VM $VirtualMachine -WarningAction silentlyContinue | Out-Null
Set-AzVMExtension -ResourceGroupName $rg -Location $region -VMName $testVMName -Name "NetworkWatcherAgentLinux" -ExtensionType "NetworkWatcherAgentLinux" -Publisher "Microsoft.Azure.NetworkWatcher" -TypeHandlerVersion "1.4" | Out-Null
# 2/ Wait for the VM to be created
####################
$VMStatus = (Get-AzVM -Name $testVMName -ResourceGroupName $rg -Status).Statuses[1].DisplayStatus
while ($VMStatus -ne "VM running" ) {
    Write-Output "VM is still being created"
    Start-Sleep -Seconds 10
}
 }
catch {
  Write-Host "An error occurred:"
  Write-Host $_
}


Write-Output "# --------------------------------------------------"
Write-Output "VM is created, Next is testing the VM connectivity to Pure1 and Azure Endpoints" 
Write-Output "." 
Write-Output "." 
Write-Output "." 

# 3/ Run Command against the Test_VM
####################

$VM1 = Get-AzVM -ResourceGroupName $rg | Where-Object -Property Name -EQ $testVMName
$networkWatcher = Get-AzNetworkWatcher | Where-Object -Property Location -EQ -Value $VM1.Location 

$endpointsToTest = "rest.cloud-support.purestorage.com", "ra.cloud-support.purestorage.com", "restricted-rest.cloud-support.purestorage.com","management.azure.com","cosmos.azure.com"

foreach ($endpoint in $endpointsToTest) {
    $TestConnectionStatus = (Test-AzNetworkWatcherConnectivity -NetworkWatcher $networkWatcher -SourceId $VM1.id -DestinationAddress $endpoint -DestinationPort 443).ConnectionStatus
    if ($TestConnectionStatus -eq "Reachable") {
        Write-Host "--> Endpoint: $endpoint ==" -NoNewline
        Write-Host " $TestConnectionStatus" -ForegroundColor Green
    } else {
        Write-Host "--> Endpoint: $endpoint ==" -NoNewline
        Write-Host " $TestConnectionStatus" -ForegroundColor Red
        Write-Host "!!!! VM can NOT connect to $endpoint, Check you outbount internet configuration !!!!" -ForegroundColor Red
    }  

}
##
#TODO: Make the commented block below faster.
##
# # Define the range of Pure1 IP addresses to test
# $endIpAddress = 253
# Write-Host "Connectivity Test for Pure1 Endpoint IP Range 52.40.255.224/27:"
# # Loop through the IP range and perform connectivity tests
# for ($i = 224; $i -le $endIpAddress; $i++) {
#     $IpAddress = "52.40.255.$i"
#     $ipAddress = $IpAddress.ToString()

#     # Start the connectivity test
#     $result = (Test-AzNetworkWatcherConnectivity -NetworkWatcher $networkWatcher  -SourceId $VM1.id -DestinationAddress $ipAddress -DestinationPort 443).ConnectionStatus

#     # Display the test results
#     Write-Host "--> Pure1 IP Address: $ipAddress == $result"
    
# }
Write-Output "#---------------------------------------------"


# 4/ Delete the temp Test_VM
Write-Output "Deleting the temporary created VM..."  
Write-Output "." 
Write-Output "." 
Write-Output "." 
$title    = 'Confirm Deleteing of the Test VM, In case no more connectivity troubleshooting is required'
$question = 'Do you want to continue?'
$choices  = '&Yes', '&No'


$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    $vm = Get-AzVm -Name $testVMName -ResourceGroupName $rg
    $diskName = $vm.StorageProfile.OsDisk.Name
    $null = $vm | Remove-AzVM -Force
    Remove-AzNetworkInterface -Name "$testVMName-NIC" -ResourceGroupName $rg -Force
    Remove-AzDisk -ResourceGroupName $rg -DiskName $diskName -Force  | Out-Null
    Remove-AzNetworkSecurityGroup -ResourceGroupName $rg -Name "$testVMName-NSG" -Force
    Write-Host "$testVMName VM is deleted"
} else {
    Write-Host "Your choice is No. $testVMName will not be deleted" -ForegroundColor Red
}

