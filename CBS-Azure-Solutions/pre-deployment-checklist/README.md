# Azure Pre-Deployment Checklist for Cloud Block Store

![paz-checklist.ps1 script to validate Azure landing zone for CBS deployment](screenshot.png)

## Usage

To run this PowerShell script, make sure you are signed in to your Azure account. Alternatively, use can Azure Cloud Shell.

### Option 1 - Use Azure Cloud Shell

1. open a Azure Cloud Shell console and make sure you have selected a Powershell runtime (by default the Azure Cloud Shell starts in Bash runtime)

1. download the script from GitHub (alternatively you can upload manually via Download/Upload files feature)

```powershell
& wget https://raw.githubusercontent.com/PureStorage-OpenConnect/cloudblockstore-scripts/main/CBS-Azure-Solutions/pre-deployment-checklist/paz-checklist.ps1
```

1. execute the script

```powershell
& paz-checklist.ps1
```


### Option 2 - Local machine

1. Install Azure Powershell Module
1. Login into Azure:

```powershell
Connect-AzAccount
```

1. Eecute the script

```powershell
& paz-checklist.ps1
```

This script will validate and verify the following:

- Check if the region where VNET is created is supported for CBS deployments.
- Check if the region has enough DSv3 or EbdsV5 Family vCPU to deploy Cloud Block Store.
- Check if the PremiumV2 or Ultra Disks are available and in which Availability Zone.
- Check if the System Subnet has outbound internet access to Pure1 cloud.
- Check if the Signed In User has the required Azure Role Assignment.

CHANGELOG

- 3/15/2024 3.0.1 Improved test for outbound connectivity (to deploy a test load balancer)
- 3/12/2024 3.0.0 Script refactored, to provide a full report of the readiness of the environment for CBS deployment
- 26/1/2024 2.0.1 Adding V20P2R2 and PremiumV2 SSD support to the script
