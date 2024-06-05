param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter you Azure Tenant Id")]
    [ValidateNotNullOrEmpty()]        
    [string]
    $tenantId
)


# Initialize an array to store the data disk information
$dataDiskInfoTSDictionary = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()
################################################

#All Azure Subscriptions
$Subscriptions = Get-AzSubscription -TenantId $tenantId

foreach ($sub in $Subscriptions) {

    $subscriptionId = $sub.id  
    # Connect to your Azure account
    Set-AzContext -Subscription $subscriptionId


    #All Virtual Machines withing the sub
    $virtualMachines = Get-AzVM 

    # Loop through each virtual machine
    $virtualMachines | ForEach-Object -Parallel {
        $vm = $_
        $subscriptionId = $using:subscriptionId
        $dataDiskInfoTSDictionary = $using:dataDiskInfoTSDictionary

        # Get the data disks attached to the virtual machine
        $dataDisks = $vm.StorageProfile.DataDisks

        $dataDisks | ForEach-Object -Parallel {
            $dataDisk = $_
                
            $subscriptionId = $using:subscriptionId
            $vm = $using:vm
            $dataDiskInfoTSDictionary = $using:dataDiskInfoTSDictionary


            # Get the size, IOPS, and bandwidth of the data disk
            $diskSize = Get-AzDisk -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskSizeGB
            $diskIops = Get-AzDisk -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskIOPSReadWrite
            $diskBandwidth = Get-AzDisk -DiskName $dataDisk.Name | Select-Object -ExpandProperty DiskMBpsReadWrite
            $diskSKU = Get-AzDisk -DiskName $dataDisk.Name | Select-Object -ExpandProperty Sku | Select-Object -ExpandProperty Name
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
                    SubscriptionID = $subscriptionId
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
                $outputObject = New-Object -TypeName PSObject -Property $dataDiskHashtable
                $dataDiskInfoTSDictionary[$dataDisk.Name] = $outputObject;
            }
        }
    }
}
################################################

# Display the data disk information as a table
$dataDiskInfoTSDictionary.Values | Format-Table VMName, SubscriptionID, Location, AvailabilityZone, OperatingSystem, DataDiskName, DiskSKU, SizeGB, Provisioned_IOPS, Utilized_Read_IOPS, Utilized_Write_IOPS, Provisioned_BW_MBps, Utilized_Read_Avg_BW_MBps, Utilized_Read_Max_BW_MBps, Utilized_Write_Avg_BW_MBps, Utilized_Write_Max_BW_MBps  

$reportName = "AzureDataDisk.csv"
$dataDiskInfoTSDictionary.Values  | Export-csv .\$reportName