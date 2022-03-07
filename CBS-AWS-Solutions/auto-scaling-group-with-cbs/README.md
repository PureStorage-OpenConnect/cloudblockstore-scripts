# Provisioning Storage for AWS Auto Scaling Group with Pure Cloud Block Store

This repository provides PoC on provisioning and managing storage for EC2 instance running in an Auto Scaling Group  
It offers two parts: 
- First the UserData script files for both Linux and Windows OS to be included under the EC2 Launch Tempalte. 
    - linux_userdata_asg.sh
    - windows_userdata_asg.ps1
- Second part is a Python script for AWS lambda which will clean up the array from the terminiated EC2.  
    - lambda_function.py


For detailed information regards this repository, please check the following knowledge base document: 
https://support.purestorage.com/Pure_Cloud_Block_Store/Provisioning_Storage_for_AWS_Auto_Scaling_Group_with_Pure_Cloud_Block_Store