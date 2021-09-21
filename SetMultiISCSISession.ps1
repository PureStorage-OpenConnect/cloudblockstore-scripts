#This script works on increasing the number of iSCSi sessions for Windows hosts connected to Cloud Block Store and running on Azure VM or AWS EC2 instances.
#Run this script on the designated host and assign from 2 to 32 iSCSI sessions.
#Follow the CBS deployment guide to get the required entries. https://support.purestorage.com/Pure_Cloud_Block_Store/Cloud_Block_Store_Deployment_and_Configuration_Guide_for_Azure

$numberOfSessions= Read-Host -Prompt 'Enter number of iSCSi session for each controller'

$winIPAddress= Read-Host -Prompt 'Enter Windows host iSCSI IP address'

$cbs_ct0_iscsi = Read-Host -Prompt 'Enter iSCSI IP address of Cloud Block Store controller 0'

$cbs_ct1_iscsi = Read-Host -Prompt 'Enter iSCSI IP address of Cloud Block Store controller 1'

Write-Host "Creating sessions with controller 0 ..."

for ($i=1; $i -le $numberOfSessions; $i++) {
    Get-IscsiTarget | Connect-IscsiTarget -InitiatorPortalAddress $winIPAddress -IsMultipathEnabled $true -IsPersistent $true -TargetPortalAddress $cbs_ct0_iscsi
}

Write-Host "Creating sessions with controller 1 ..."

for ($i=1; $i -le $numberOfSessions; $i++) {
    Get-IscsiTarget | Connect-IscsiTarget -InitiatorPortalAddress $winIPAddress -IsMultipathEnabled $true -IsPersistent $true -TargetPortalAddress $cbs_ct1_iscsi
}

Write-Host "The number of iSCSi sessions have been increased to $numberOfSessions per CBS controller"
Write-Host "To confirm the total number of sessions, run 'Get-IscsiSession | measure'" 
