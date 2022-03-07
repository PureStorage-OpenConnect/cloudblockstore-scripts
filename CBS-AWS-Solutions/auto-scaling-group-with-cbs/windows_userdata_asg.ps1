#######################
## Enter you Environment Variables 
#######################

# 'Enter IP address or FQDN of Cloud Block Store'
$CBS_IP_FQDN = '20.0.0.182'

# Enter iSCSI IP address of Cloud Block Store controller 0
$cbs_ct0_iscsi = '20.0.0.159'

# Enter iSCSI IP address of Cloud Block Store controller 1
$cbs_ct1_iscsi = '20.0.0.109'

# Enter the Host Group Name 
$HostGroupName = 'ASG-CBS-Hgroup'

# Get and assign the Host Name by InstanceId
$HostName = Get-EC2InstanceMetadata -Category InstanceId

# Enter the Volume Size
$VolumeSize = '214748364800' #Note: Size is in Bytes, EX: 200GiB = 1024^(3)*200

# 'Enter number of iSCSi session for each controller'
$numberOfSessions= '32'

#######################
## Install Modules
#######################
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PureStoragePowerShellSDK2 -Force

#######################
## Checking Initiator - Array connectivity 
#######################

if (Test-Connection -TcpPort 22  -TargetName $CBS_IP_FQDN  -Quiet) {
    Write-Output "Array Managment Interface is reachable via ssh. "
    if ((Test-Connection -TcpPort 3260  -TargetName $cbs_ct0_iscsi -Quiet) -and (Test-Connection -TcpPort 3260  -TargetName $cbs_ct1_iscsi -Quiet)) {
        Write-Output "Array Managment Interface is reachable via ssh. "

        #######################
        ## CBS Authentication
        #######################

        $username = "pureuser"
        $password = ConvertTo-SecureString "pureuser" -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
        $FlashArray = Connect-Pfa2Array -EndPoint $CBS_IP_FQDN -Credential $Credential -IgnoreCertificateError



        #######################
        ## CBS SDK Logging 
        #######################

        # Start SDK logging to a file calles session.log in the current folder
        Set-Pfa2Logging -LogFilename C:\ProgramData\Amazon\EC2-Windows\Launch\Log\session.log


        if (((Get-WindowsFeature Multipath-io).InstallState) -like "Available") {

            #######################
            ## CBS Operations 
            #######################

            # Retrive IQN and create a host
            $IQN = (Get-InitiatorPort | Where-Object { $_.NodeAddress -like '*iqn*' }).NodeAddress
            New-Pfa2Host -Array $FlashArray -Name $HostName -Iqns $IQN

            # If not exsited, create a new Host Group
            If ((Get-Pfa2HostGroup -Array $FlashArray).Name -notcontains $HostGroupName) {
                New-Pfa2HostGroup -Array $FlashArray -Name $HostGroupName
            }

            # Add a host to the group
            New-Pfa2HostGroupHost -GroupNames $HostGroupName -MemberNames $HostName

            # Create a new volume 
            New-Pfa2Volume -Array $FlashArray -Name $HostName -Provisioned $VolumeSize

            # Connect volume to host
            New-Pfa2Connection -Array $FlashArray -VolumeNames $HostName -HostNames $HostName


            #######################
            ## Configure iSCSi and MultiPath IO
            #######################

            Set-Service -Name msiscsi -StartupType Automatic
            Start-Service -Name msiscsi
            Add-WindowsFeature -Name 'Multipath-IO' -Restart
        }

        if (((Get-WindowsFeature Multipath-io).InstallState) -like "Installed") {

            if ((Get-IscsiTargetPortal).TargetPortalAddress -notcontains "$cbs_ct0_iscsi"){
                New-IscsiTargetPortal -TargetPortalAddress $cbs_ct0_iscsi
                for ($i=1; $i -le $numberOfSessions; $i++) {
                    Get-IscsiTarget | Connect-IscsiTarget -InitiatorPortalAddress (Get-NetIPAddress |Where-Object {$_.InterfaceAlias -like "Ethernet" -and $_.AddressFamily -like "IPv4"}).IPAddress -IsMultipathEnabled $true -IsPersistent $true -TargetPortalAddress $cbs_ct0_iscsi
                }       
            }       
            if ((Get-IscsiTargetPortal).TargetPortalAddress -notcontains "$cbs_ct1_iscsi"){
                New-IscsiTargetPortal -TargetPortalAddress $cbs_ct1_iscsi
                for ($i=1; $i -le $numberOfSessions; $i++) {
                    Get-IscsiTarget | Connect-IscsiTarget -InitiatorPortalAddress (Get-NetIPAddress |Where-Object {$_.InterfaceAlias -like "Ethernet" -and $_.AddressFamily -like "IPv4"}).IPAddress -IsMultipathEnabled $true -IsPersistent $true -TargetPortalAddress $cbs_ct1_iscsi
                } 
            }

            if (((Get-MSDSMAutomaticClaimSettings).iSCSI) -ne "True") {
                Enable-MSDSMAutomaticClaim -BusType iSCSI -Confirm:$false
            }
            if (((Get-MSDSMAutomaticClaimSettings).iSCSI) -notcontains "PURE") {
                New-MSDSMSupportedHw -VendorId PURE -ProductId FlashArray
            }
            if (Get-MSDSMGlobalDefaultLoadBalancePolicy -ne "LQD") {
                Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy LQD
            }
            if (((Get-MPIOSetting).CustomPathRecoveryTime) -ne "20") {
                Set-MPIOSetting -NewPathRecoveryInterval 20
            }
            if (((Get-MPIOSetting).UseCustomPathRecoveryTime) -ne "Enabled") {
                Set-MPIOSetting -CustomPathRecovery Enabled
            }
            if (((Get-MPIOSetting).PDORemovePeriod) -ne "30") {
                Set-MPIOSetting -NewPDORemovePeriod 30
            }
            if (((Get-MPIOSetting).DiskTimeoutValue) -ne "60") {
                Set-MPIOSetting -NewDiskTimeout 60
            }
            if (((Get-MPIOSetting).PathVerificationState) -ne "Enabled") {
                Set-MPIOSetting -NewPathVerificationState Enabled
            }
        }

        #######################
        ## Initialize and format the volume 
        #######################

        if ((((Get-Disk).OperationalStatus) -contains "Offline") -and ((((Get-Disk).FriendlyName) -eq "PURE FlashArray"))) {
            Get-Disk | Where-Object {$_.OperationalStatus -eq "Offline"} | Set-Disk -IsOffline $false 
            Get-Disk | Where-Object PartitionStyle –Eq 'RAW' | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel “CBS-Volume” -Confirm:$false
        }

        

    }
} else {
    Write-Error "Array managements or iSCSi Interfaces cant be reached, please check the connectivity" 
}


