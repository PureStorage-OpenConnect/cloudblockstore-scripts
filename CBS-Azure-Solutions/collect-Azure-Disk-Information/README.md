# Collect Azure Managed Disk information using Az PowerShell SDK

1. Open shell.azure.com
2. copy the script Get-AzDataDisk-Storage-IO-BW.ps1
3. On Azure CloudShell, open the editor and paste the script, then save it. 
```bash
code Get-AzDataDisk-Storage-IO-BW.ps1
```
4. Execute the script. 
```powershell
.\Get-AzDataDisk-Storage-IO-BW.ps1 -subscriptionId <Your scoped subscription ID> -resourceGroup <OPTIONAL>
```

`-resourceGroup` is optional argument. If selected only the virtual machine within the resource group will be scoped for the info collection. 