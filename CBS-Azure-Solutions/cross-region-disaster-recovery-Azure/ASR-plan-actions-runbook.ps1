param (
    [Object]$RecoveryPlanContext,
    [Boolean]$TestExecution
)
Write-Verbose "Connecting to Azure..."
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

if($TestExecution)
{
    Write-Output "Using TestExecution Flag"
    $RecoveryPlanContextObj = $RecoveryPlanContext | ConvertFrom-Json
}

else
{
    $RecoveryPlanContextObj = $RecoveryPlanContext
    Write-Output "Not Using TestExecution Flag"
}

$VMMapColl = $RecoveryPlanContextObj.VmMap
$FailoverDir = $RecoveryPlanContextObj.FailoverDirection

Write-Output  "FailoverDirection is: $FailoverDir" 

if($VMMapColl -ne $null)
{
    $VMinfo = $VMMapColl | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
	$vmMap = $RecoveryPlanContext.VmMap
    foreach($VMID in $VMinfo)
    {
        $VM = $vmMap.$VMID                
            if( !(($VM -eq $Null) -Or ($VM.ResourceGroupName -eq $Null) -Or ($VM.RoleName -eq $Null))) {
   				$Rolename  = $VM.RoleName
				$RG = $VM.ResourceGroupName
				Start-AzAutomationRunbook -AutomationAccountName "Automation-UKSouth" `
					-ResourceGroupName "PureDemoRG" `
					-Name  "Provision-CBS" `
					-Parameters @{"ResourceGroupName"="$RG";"VMName"="$Rolename";"FailoverDirection"="$FailoverDir"} `
					-RunOn "win-hybrid-worker" `
					-MaxWaitSeconds 300 -Wait
            }

    }
 
}
else
{
     Write-Verbose -Message "VMMapColl Variable is Null"
}






