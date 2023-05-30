<#
  Get-AzDataDisk-IO-BW.ps1 
  Version:        1.0.1
  Author:         Adam Mazouz @ Pure Storage
.SYNOPSIS
    This script retrives all Azure Managed Data Disks attached to Azure VM. It lists Size, IOPS, BW, OS, Availability Zone, Disk SKU Name

.CHANGELOG
    - Added peak (Max) Consumed IOPS and Bandwidth infomration
.INPUTS
      - Azure Subscription Id.
      - Resource Group 
.OUTPUTS
      - Print out table of Azure VM Name, Size, IOPS, BW, OS, Availability Zone, Disk SKU. 
      - Output all the informwation into CSV report.
.EXAMPLE
    Option 1: Use Azure CloudShell to paste the script and run it
        .\Get-AzDataDisk-IO-BW.ps1
    Option 2: Or use your local machine to install Azure Powershell Module and make sure to login to Azure first
        Connect-AzAccount
#>
<#
.DISCLAIMER
The sample script and documentation are provided AS IS and are not supported by the author or the author's employer, unless otherwise agreed in writing. You bear all risk relating to the use or performance of the sample script and documentation. 
The author and the author's employer disclaim all express or implied warranties (including, without limitation, any warranties of merchantability, title, infringement 	or fitness for a particular purpose). In no event shall the author, the author's employer or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever arising out of the use or performance of the sample script and 	documentation (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss), even if 	such person has been advised of the possibility of such damages.
#>


param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter you Azure Subscription Id")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript(
        { $null -ne (Get-AzSubscription -SubscriptionId $_ -WarningAction silentlyContinue) },
        ErrorMessage = "Subscription was not found in tenant {0} . Please verify that the subscription exists in the signed-in tenant."
    )]         
    [string]
    $subscriptionId,

    
    [Parameter(Mandatory = $false, HelpMessage = "(Optional) Enter your Resource Group Name")]
    [ValidateScript(
        { $null -ne (Get-AzResourceGroup -name $_ -WarningAction silentlyContinue) },
        ErrorMessage = "Resource Group was not found in tenant {0}."
    )]  
    [string]
    $resourceGroup
)

# # Connect to your Azure account
# Connect-AzAccount

# Connect to your Azure account
Set-AzContext -Subscription $subscriptionId

# Install the Azure PowerShell module if it's not already installed
if (-not(Get-Module Az.Accounts)) {
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
}

if ([string]::IsNullOrEmpty($resourceGroup))  {
    $virtualMachines = Get-AzVM -ResourceGroupName $resourceGroup
} else {
    # Get all the virtual machines in your subscription
    $virtualMachines = Get-AzVM 
}


# Initialize an array to store the data disk information
$dataDiskInfo = @()
################################################

# Loop through each virtual machine
foreach ($vm in $virtualMachines) {

    # Get the data disks attached to the virtual machine
    $dataDisks = $vm.StorageProfile.DataDisks

    foreach ($dataDisk in $dataDisks) {
        # Get the size, IOPS, and bandwidth of the data disk
        $diskSize = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskSizeGB
        $diskIops = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskIOPSReadWrite
        $diskBandwidth = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskMBpsReadWrite
        $diskSKU = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty Sku | Select-Object -ExpandProperty Name
        $resourceGroup = $vm.ResourceGroupName
        $dataDiskName = $dataDisk.Name
        $location = $vm.Location
        $operatingSystem = $vm.StorageProfile.OsDisk.OsType

        # Check if VM is deplyed in availabilityZone or None
        $availabilityZone = $vm.Zones
        if ([string]::IsNullOrWhiteSpace($availabilityZone)) {
            $availabilityZone = "No Zone"
        } else {
            $availabilityZone = $vm.Zones
        }

        # Get consumed utilized storage IO (IOPS,BW) for the data disk

            ## Specify the time range for the metrics data
        $startTime = (Get-Date).AddDays(-1)  # Start time (e.g., 24 hours ago) <<- Change to number of days or switch to hours .AddHours(-24)
        # $endTime = Get-Date                    # End time (current time)
        $TimeGrain = [TimeSpan]::Parse("1:00:00")
        $MetricName = @("Composite Disk Write Operations/sec", "Composite Disk Read Operations/sec", "Composite Disk Read Bytes/sec", "Composite Disk Write Bytes/sec")

            ## Get the consumed metrics for the managed disk
        $metrics = Get-AzMetric `
            -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/disks/$dataDiskName" `
            -StartTime $startTime `
            -TimeGrain $TimeGrain `
            -MetricNames $MetricName `
            -WarningAction silentlyContinue

        foreach ($Metric in $metrics)
        {
            $Resuts += $Metric.Data | Select-Object TimeStamp, Average, @{Name="Metric"; Expression={$Metric.Name.Value}}
        }
        ################################################
                    # -AggregationType Average `
                    # -TimeGrain $TimeGrain `
        # $Resuts | Sort-Object -Property TimeStamp, Metric | Format-Table
        $disk_IOPS_read_Avg = ($Resuts | Where-Object { $_.Metric -eq "Composite Disk Read Operations/sec" } | Measure-Object -Property Average -Average).Average 
        $disk_IOPS_write_Avg = ($Resuts | Where-Object { $_.Metric -eq "Composite Disk Write Operations/sec" } | Measure-Object -Property Average -Average).Average  
        $disk_BW_read_Avg = ($Resuts | Where-Object { $_.Metric -eq "Composite Disk Read Bytes/sec" } | Measure-Object -Property Average -Average).Average 
        $disk_BW_read_Max = ($Resuts | Where-Object { $_.Metric -eq "Composite Disk Read Bytes/sec" } | Measure-Object -Property Average -Maximum).Maximum 
        $disk_BW_write_Avg = ($Resuts | Where-Object { $_.Metric -eq "Composite Disk Write Bytes/sec" } | Measure-Object -Property Average -Average).Average  
        $disk_BW_write_Max = ($Resuts | Where-Object { $_.Metric -eq "Composite Disk Write Bytes/sec" } | Measure-Object -Property Average -Maximum).Maximum  


        # Check if the same data disk has already been added
        $existingDisk = $dataDiskInfo | Where-Object { $_.DataDiskName -eq $dataDisk.Name }
        if ($existingDisk) {
            # Update the existing disk information with the latest values
            $existingDisk.SizeGB = $diskSize
            $existingDisk.Provisioned_IOPS = $diskIops
            $existingDisk.Provisioned_BW_MBps = $diskBandwidth
        }
        else {
            # Create a hashtable to store the data disk information
            $dataDiskHashtable = @{
                VMName = $vm.Name
                DataDiskName = $dataDiskName
                SizeGB = $diskSize
                Provisioned_IOPS = $diskIops 
                Provisioned_BW_MBps = $diskBandwidth 
                DiskSKU =  $diskSKU
                AvailabilityZone = $availabilityZone
                OperatingSystem = $operatingSystem
                Location = $location
                Utilized_Read_IOPS = $disk_IOPS_read_Avg
                Utilized_Write_IOPS = $disk_IOPS_write_Avg 
                Utilized_Read_Avg_BW_MBps = $disk_BW_read_Avg / 1MB
                Utilized_Read_Max_BW_MBps = $disk_BW_read_Max / 1MB
                Utilized_Write_Avg_BW_MBps = $disk_BW_write_Avg / 1MB
                Utilized_Write_Max_BW_MBps = $disk_BW_write_Max / 1MB
            }

            # Add the hashtable to the array
            $dataDiskInfo += New-Object -TypeName PSObject -Property $dataDiskHashtable
        }
    }
}
################################################

# Display the data disk information as a table
$dataDiskInfo | Format-Table VMName, Location, AvailabilityZone, OperatingSystem, DataDiskName, DiskSKU, SizeGB, Provisioned_IOPS, Utilized_Read_IOPS, Utilized_Write_IOPS, Provisioned_BW_MBps, Utilized_Read_Avg_BW_MBps, Utilized_Read_Max_BW_MBps, Utilized_Write_Avg_BW_MBps, Utilized_Write_Max_BW_MBps  

$reportName = "AzureDataDisk.csv"
$dataDiskInfo  | Export-csv .\$reportName


