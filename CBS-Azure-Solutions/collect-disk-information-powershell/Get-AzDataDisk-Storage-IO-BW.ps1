<#
  Get-AzDataDisk-IO-BW.ps1 
  Version:        1.2
  Authors:        Adam Mazouz @ Pure Storage
                  Vaclav Jirvosky @ Pure Storage
.SYNOPSIS
    This script retrives all Azure Managed Data Disks attached to Azure VM. It lists Size, IOPS, BW, OS, Availability Zone, Disk SKU Name

.CHANGELOG
    - 1.2 Improved execution time by adding concurrency 
    - 1.1 Added peak (Max) Consumed IOPS and Bandwidth infomration
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

    
    [Parameter(HelpMessage = "(Optional) Enter your Resource Group Name")]  
    [string]
    $resourceGroupName
)

# # Connect to your Azure account
# Connect-AzAccount

# Connect to your Azure account
Set-AzContext -Subscription $subscriptionId

# Install the Azure PowerShell module if it's not already installed
if (-not(Get-Module Az.Accounts)) {
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
}

if (-not [string]::IsNullOrEmpty($resourceGroupName)) {
    if (Get-AzResourceGroup -name $resourceGroupName -WarningAction silentlyContinue) {
        $virtualMachines = Get-AzVM -ResourceGroupName $resourceGroupName
    } else {
        Write-Host "The Resource Group Name entered does not exist" -ForegroundColor Red
        Exit
    }
} else {
    # Get all the virtual machines in your subscription
    $virtualMachines = Get-AzVM 
    Write-Host "#_________________________________________________________"
    Write-Host "# No Resource Group Selected, All Virtual Machine info in the subscription will be collected" -ForegroundColor Yellow
}


# Initialize an array to store the data disk information
$dataDiskInfoTSDictionary = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()
################################################

# Loop through each virtual machine
$virtualMachines | ForEach-Object -Parallel {
    $vm = $_
    $subscriptionId = $using:subscriptionId
    $resourceGroupName = $using:resourceGroupName
    $dataDiskInfoTSDictionary = $using:dataDiskInfoTSDictionary

     # Get the data disks attached to the virtual machine
     $dataDisks = $vm.StorageProfile.DataDisks

     $dataDisks | ForEach-Object -Parallel {
         $dataDisk = $_
             
         $subscriptionId = $using:subscriptionId
         $resourceGroupName = $using:resourceGroupName
         $vm = $using:vm
         $dataDiskInfoTSDictionary = $using:dataDiskInfoTSDictionary


        # Get the size, IOPS, and bandwidth of the data disk
        $diskSize = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskSizeGB
        $diskIops = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskIOPSReadWrite
        $diskBandwidth = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskMBpsReadWrite
        $diskSKU = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name | Select-Object -ExpandProperty Sku | Select-Object -ExpandProperty Name
        $resourceGroup = $vm.ResourceGroupName
        $dataDiskName = $dataDisk.Name
        $location = $vm.Location
        $operatingSystem = $vm.StorageProfile.OsDisk.OsType

        #Get Network Info
        $vmnic = ($vm.NetworkProfile.NetworkInterfaces.id).Split('/')[-1]
        $vmnicinfo = Get-AzNetworkInterface -Name $vmnic
        $vmvnet = $((($vmnicinfo.IpConfigurations.subnet.id).Split('/'))[-3])

        # Check if VM is deplyed in availabilityZone or None
        $availabilityZone = $vm.Zones
        if ([string]::IsNullOrWhiteSpace($availabilityZone)) {
            $availabilityZone = "No Zone"
        } else {
            $availabilityZone = $vm.Zones | Select-Object -Index 0
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
            $Results += $Metric.Data | Select-Object TimeStamp, Average, @{Name="Metric"; Expression={$Metric.Name.Value}}
        }
        ################################################
                    # -AggregationType Average `
                    # -TimeGrain $TimeGrain `
        # $Results | Sort-Object -Property TimeStamp, Metric | Format-Table
        $disk_IOPS_read_Avg = ($Results | Where-Object { $_.Metric -eq "Composite Disk Read Operations/sec" } | Measure-Object -Property Average -Average).Average 
        $disk_IOPS_write_Avg = ($Results | Where-Object { $_.Metric -eq "Composite Disk Write Operations/sec" } | Measure-Object -Property Average -Average).Average  
        $disk_BW_read_Avg = ($Results | Where-Object { $_.Metric -eq "Composite Disk Read Bytes/sec" } | Measure-Object -Property Average -Average).Average 
        $disk_BW_read_Max = ($Results | Where-Object { $_.Metric -eq "Composite Disk Read Bytes/sec" } | Measure-Object -Property Average -Maximum).Maximum 
        $disk_BW_write_Avg = ($Results | Where-Object { $_.Metric -eq "Composite Disk Write Bytes/sec" } | Measure-Object -Property Average -Average).Average  
        $disk_BW_write_Max = ($Results | Where-Object { $_.Metric -eq "Composite Disk Write Bytes/sec" } | Measure-Object -Property Average -Maximum).Maximum  


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
                VirtualNetwork = $vmvnet
            }

            # Add the hashtable to the array
            $outputObject = New-Object -TypeName PSObject -Property $dataDiskHashtable
            $dataDiskInfoTSDictionary[$dataDisk.Name] = $outputObject;
        }
    }
}
################################################

# Display the data disk information as a table
$dataDiskInfoTSDictionary.Values | Format-Table VMName, Location, AvailabilityZone, OperatingSystem, DataDiskName, DiskSKU, SizeGB, Provisioned_IOPS, Utilized_Read_IOPS, Utilized_Write_IOPS, Provisioned_BW_MBps, Utilized_Read_Avg_BW_MBps, Utilized_Read_Max_BW_MBps, Utilized_Write_Avg_BW_MBps, Utilized_Write_Max_BW_MBps, VirtualNetwork

$reportName = "AzureDataDisk.csv"
$dataDiskInfoTSDictionary.Values  | Export-csv .\$reportName


