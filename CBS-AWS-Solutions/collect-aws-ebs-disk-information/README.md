# Collect AWS Elastic Block Store Disk information using AWS PowerShell SDK

Follow the below step to collect Azure VM data disk information.

1. Install AWS Tools for Powershell - <https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up-windows.html>
    * Install-Module -Name AWS.Tools.Installer
2. Install EC2 & EBS Module
    * Install-AWSToolsModule AWS.Tools.EC2,AWS.Tools.EBS
3. Log in to AWS CLI
    * New-AWSCredential (Can use Credential or Keys)
4. Copy/Download the script Get-AWS-EBS-Volume-Information.ps1
5. Execute the script.

```powershell
.\Get-AWS-EBS-Volume-Information.ps1
```

## Output Screenshot

1. Display the data disk information as a table on the terminal
![screenshot_1](/CBS-AWS-Solutions/collect-aws-ebs-disk-information/script_output.png)

2. Save the information as a CSV
![screenshot_2](/CBS-AWS-Solutions/collect-aws-ebs-disk-information/csv_output.png)
