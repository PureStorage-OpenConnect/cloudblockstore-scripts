param (
	[String]$ResourceGroupName,
	[String]$VMName,
	[String]$FailoverDirection
)

###########
#Variables
###########
$CBSMngmtIPProd = "10.4.1.4"
$TargetProtectionGroupProd = "CBS-Prod-US:Win-PG"
$CBSMngmtIPRecovery = "10.2.2.4"
$TargetProtectionGroupRecovery = "CBS-DR-WEurope:Win-PG"

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext



if ($FailoverDirection -eq "PrimaryToSecondary") {
	$CBS_IP_FQDN = $CBSMngmtIPProd 
	$trgProtectionGroup = $TargetProtectionGroupProd
}
else{
	$CBS_IP_FQDN = $CBSMngmtIPRecovery
	$trgProtectionGroup = $TargetProtectionGroupRecovery 
}



Write-Verbose "Connecting to CBS array..." 
$username = "pureuser"
$password = ConvertTo-SecureString "pureuser" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
$CBSArray = Connect-Pfa2Array -EndPoint $CBS_IP_FQDN -Credential $Credential -IgnoreCertificateError



#Get Most Recent Completed Snapshot
Write-Verbose "Obtaining the most recent snapshot for the protection group..." 
$MostRecentSnapshots = Get-Pfa2ProtectionGroupSnapshot -Array $CBSArray -Name $trgProtectionGroup | Sort-Object created -Descending | Select-Object -Property name -First 2

# Check that the last snapshot has been fully replicated
$FirstSnapStatus = Get-Pfa2ProtectionGroupSnapshotTransfer -Array $CBSArray -Name $MostRecentSnapshots[0].name

# If the latest snapshot's completed property is null, then it hasn't been fully replicated - the previous snapshot is good, though
if ($null -ne $FirstSnapStatus.completed) {
    $MostRecentSnapshot = $MostRecentSnapshots[0].name
}
else {
    $MostRecentSnapshot = $MostRecentSnapshots[1].name
}


# Offline the Disk
Write-Verbose "Onlining the volume..." 
$Command = 'Get-Disk | Where-Object {$_.FriendlyName -eq "PURE FlashArray"} | Set-Disk -IsOffline $true'

# Save the command to a local file
Set-Content -Path .\script1.ps1 -Value $Command
Invoke-AzVMRunCommand `
    -ResourceGroupName $ResourceGroupName `
    -VMName $VMName `
    -CommandId 'RunPowerShellScript' `
    -ScriptPath '.\script1.ps1'

# Perform the DR volume overwrite
Write-Verbose "Overwriting the data volume with a copy of the most recent snapshot..." 
$SnapShotSource = New-Pfa2ReferenceObject -Name ($MostRecentSnapshot + '.' + $VMName)
New-Pfa2Volume -Array $array -Name $VMName -Source $SnapShotSource -Overwrite $true | Out-Null


# Online the Disk
Write-Verbose "Onlining the volume..." 
$Command = 'Get-Disk | Where-Object {$_.FriendlyName -eq "PURE FlashArray"} | Set-Disk -IsOffline $false'

# Save the command to a local file
Set-Content -Path .\script2.ps1 -Value $Command
Invoke-AzVMRunCommand `
    -ResourceGroupName $ResourceGroupName `
    -VMName $VMName `
    -CommandId 'RunPowerShellScript' `
    -ScriptPath '.\script2.ps1'



