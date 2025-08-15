<#
    Get-AWS-EBS-Volume-Information.ps1
    Version:        1.2
    Authors:        David Stamen @ Pure Storage
    Edited:         Mike Carpendale @ Pure Storage
    Modified to identify root volumes.

    .CHANGELOG
    - 1.0 Initial Release
    - 1.1 Added tags and throughput
    - 1.2 Added support to identify root volumes
#>
try {
    Write-Host "Verifying AWS session..." -ForegroundColor Cyan
    Get-STSCallerIdentity -ErrorAction Stop | Out-Null
    Write-Host "AWS session confirmed. Proceeding..." -ForegroundColor Green
}
catch {
    Write-Warning "No active AWS session found or credentials are not valid."
    Write-Warning "Please configure your credentials using 'Set-AWSCredential', environment variables, or an EC2 instance profile."
    return # Stop script execution
}

# Get all regions
#$Regions = (Get-AWSRegion).Region
$Regions = @("ap-southeast-1", "us-west-2")

# PERFORMANCE: Use PowerShell's pipeline feature to collect results efficiently.
$VolumeDetailsOutArray = foreach ($Region in $Regions) {
    # UX: Add a progress bar for better user feedback.
    $i = 0
    Write-Progress -Activity "Processing AWS Regions" -Status "Checking Region: $Region" -PercentComplete (($Regions.IndexOf($Region)) / $Regions.Count * 100)

    try {
        # Get all volumes in the current region just once.
        $volumesInRegion = Get-EC2Volume -Region $Region
        if (-not $volumesInRegion) {
            Write-Host "No volumes found in $Region." -ForegroundColor Yellow
            continue # Skip to the next region
        }

        # PERFORMANCE: Get all instances in the region ONCE and create a hash table for fast lookups.
        $instanceMap = @{}
        Get-EC2Instance -Region $Region | ForEach-Object { $instanceMap[$_.Instances.InstanceId] = $_.Instances }

        # Process each volume found in the region.
        foreach ($Volume in $volumesInRegion) {
            # REFACTOR: Use the modern [PSCustomObject] and populate common properties first.
            $volumeObj = [PSCustomObject]@{
                Region           = $Region
                AvailabilityZone = $Volume.AvailabilityZone
                VolumeId         = $Volume.VolumeId
                VolumeType       = $Volume.VolumeType
                Size             = $Volume.Size
                Iops             = $Volume.Iops
                Throughput       = $Volume.Throughput
                State            = $Volume.State
                Tags             = ($Volume.Tags | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "
                Name             = ($Volume.Tags | Where-Object { $_.Key -eq "Name" }).Value
                # Initialize instance-specific properties to null
                InstanceId       = $null
                InstanceState    = $null
                InstanceType     = $null
                Device           = $null
                IsRootVolume     = $false # Default to false
                PlatformDetails  = $null
            }

            # Handle attached ('in-use') volumes
            if ($Volume.State -eq 'in-use') {
                $attachment = $Volume.Attachments[0] # A volume can only be attached to one instance
                $volumeObj.InstanceId = $attachment.InstanceId
                $volumeObj.Device = $attachment.Device

                # PERFORMANCE: Use the fast hash table lookup instead of a new API call.
                $instance = $instanceMap[$attachment.InstanceId]
                if ($instance) {
                    $volumeObj.InstanceState = $instance.State.Name
                    $volumeObj.InstanceType = $instance.InstanceType
                    $volumeObj.PlatformDetails = $instance.PlatformDetails
                    # The key check for root volume status
                    if ($instance.RootDeviceName -eq $attachment.Device) {
                        $volumeObj.IsRootVolume = $true
                    }
                }
            }
            # Output the completed object to the pipeline, which will be collected in $VolumeDetailsOutArray
            $volumeObj
        }
    }
    catch {
        Write-Warning "Unable to search for volumes in $Region"
    }
}

# Close the progress bar
Write-Progress -Activity "Processing AWS Regions" -Completed

if (-not $VolumeDetailsOutArray) {
    Write-Host "No Volumes found across all regions." -ForegroundColor Yellow
}
else {
    # UX: Create a timestamped file name to avoid overwriting previous reports.
    $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $filePath = "AWSEBSExportInfo-$timestamp.csv"

    Write-Host "Exporting data to $filePath" -ForegroundColor Green
    $VolumeDetailsOutArray | Export-Csv -NoTypeInformation -Path $filePath

    # Display a summary table in the console.
    #$VolumeDetailsOutArray | Format-Table Region, InstanceId, VolumeId, Device, IsRootVolume, Size, VolumeType
}