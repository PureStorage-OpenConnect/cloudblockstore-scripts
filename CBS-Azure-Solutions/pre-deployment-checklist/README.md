# Azure Pre-Deployment Checklist for Cloud Block Store


### Note: **To run this PowerShell script, make sure you are signed in to your Azure account. Alternatively, use can Azure Console Cloud Shell.**
  

This script will validate and verify the following:

- Check if the region where VNET is created is supported for CBS deployments.
- Check if the region has enough DSv3 Family vCPU to deploy Cloud Block Store.
- Check if the Ultra Disks are available and in which Availability Zone.
- Check if the System Subnet has outbound internet access.
- Check if the SginInUseer has the required Azure Role Assignment.