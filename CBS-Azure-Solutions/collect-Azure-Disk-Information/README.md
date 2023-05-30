# Collect Azure Managed Disk information using Az PowerShell SDK

Follow the below step to collect Azure VM data disk information.

1. Open `shell.azure.com`
2. copy the script Get-AzDataDisk-Storage-IO-BW.ps1
3. On Azure CloudShell, open the editor and paste the script, then save it. 
```bash
code Get-AzDataDisk-Storage-IO-BW.ps1
```
4. Execute the script. 
```powershell
.\Get-AzDataDisk-Storage-IO-BW.ps1 -subscriptionId <Your scoped subscription ID> -resourceGroup <Your scoped resource group name>
```
`-subscriptionId` (REQUIRED) if the ID is not within the signed-in Azure Tenet, the script fails.

`-resourceGroup` (OPTIONAL) If selected only the virtual machine within the resource group will be scoped for the info collection. 

## Output Screenshot
![screenshot](/cloudblockstore-scripts/CBS-Azure-Solutions/collect-Azure-Disk-Information/output_example.jpg)