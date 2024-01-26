# Azure Pre-Deployment Checklist for Cloud Block Store


### Note: **To run this PowerShell script, make sure you are signed in to your Azure account. Alternatively, use can Azure Console Cloud Shell.**
Option 1: Use Azure CloudShell to paste the script and run it
```
& paz-checklist.ps1
```
Option 2: Or use your local machine to install Azure Powershell Module and make sure to login to Azure first:
```
Connect-AzAccount
```
Then execute the PS script
```
& paz-checklist.ps1
```

This script will validate and verify the following:

- Check if the region where VNET is created is supported for CBS deployments.
- Check if the region has enough DSv3 or EbdsV5 Family vCPU to deploy Cloud Block Store.
- Check if the PremiumV2 or Ultra Disks are available and in which Availability Zone.
- Check if the System Subnet has outbound internet access.
- Check if the Signed In User has the required Azure Role Assignment.


CHANGELOG
- 26/1/2024 2.0.1 Adding V20P2R2 and PremiumV2 SSD support to the script