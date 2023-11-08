<#
    Get-AWS-EBS-Volume-Information.ps1
    Version:        1.0
    Authors:        David Stamen @ Pure Storage
#>

# Get all regions
$Regions = (Get-AWSRegion).Region

# Get all Volumes in each region
$Volumes = foreach ($Region in $Regions) {
    try {
        #Write-Host "Getting Volumes in $Region"
        Get-EC2Volume -Region $Region
    }
    catch {
        Write-Warning "Unable to search for volumes in $Region"
    }
}

#Construct an out-array to use for data export for the Volume Information
$VolumeDetailsOutArray = @()
#The computer loop you already have
foreach ($Volume in $Volumes) {
        #Construct an object for the Collection
        $myobj = "" | Select-Object "Region","AvailabilityZone","VolumeType","Size","Iops","VolumeId","Name","Device","PlatformDetails","InstanceId","State","InstanceState","InstanceType"

        #Fill the object with the values mentioned above
        if ($Volume.State -eq "available") {
            $myobj.VolumeId = $Volume.VolumeId
            $myobj.VolumeType = $Volume.VolumeType
            $myobj.State = $Volume.State
            $myobj.Region = $Volume.AvailabilityZone.Substring(0,$Volume.AvailabilityZone.Length-1)
            $myobj.AvailabilityZone = $Volume.AvailabilityZone
            $myobj.Iops = $Volume.Iops
            $myobj.Size = $Volume.Size
            $myobj.Name = ($Volume.Tags | ? {$_.Key -EQ "Name"}).Value | Out-String -Stream

            #Add the objects to the Volume Out Arrays
            $VolumeDetailsOutArray += $myobj

            #Wipe the temp object just to be sure
            $myobj = $null
        }
        else {
            $Instance = Get-EC2Instance -Instance $Volume.Attachments.InstanceId -Region $Volume.AvailabilityZone.Substring(0,$Volume.AvailabilityZone.Length-1)

            if ($Instance.Instances.RootDeviceName -eq $Volume.Attachments.Device) {
            }
            else {
                $myobj.Device = $Volume.Attachments.Device
                $myobj.InstanceId = $Volume.Attachments.InstanceId
                $myobj.InstanceState = $Instance.Instances.State.Name.Value
                $myobj.InstanceType = $Instance.Instances.InstanceType.Value
                $myobj.PlatformDetails = $Instance.Instances.PlatformDetails
                $myobj.VolumeId = $Volume.VolumeId
                $myobj.VolumeType = $Volume.VolumeType
                $myobj.State = $Volume.State
                $myobj.Region = $Volume.AvailabilityZone.Substring(0,$Volume.AvailabilityZone.Length-1)
                $myobj.AvailabilityZone = $Volume.AvailabilityZone
                $myobj.Iops = $Volume.Iops
                $myobj.Size = $Volume.Size
                $myobj.Name = ($Volume.Tags | ? {$_.Key -EQ "Name"}).Value | Out-String -Stream

                #Add the objects to the Volume Out Arrays
                $VolumeDetailsOutArray += $myobj

                #Wipe the temp object just to be sure
                $myobj = $null
            }
        }
    }

if ($Volumes.Count -eq 0) {
        Write-Host No Volumes in the account -ForegroundColor Yellow
}
else {
    #After the loop export the array to CSV and open
    $VolumeDetailsOutArray | Export-Csv -NoTypeInformation -Path VolumeInfo.csv
    $VolumeDetailsOutArray | Format-Table
}