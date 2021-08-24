# Linux Migration Scripts

The scripts samples work on configure cloud VMs and provistion the replicated storage from Cloud Block Store during/after migration. *It works on Ubuntu machines. More Linux flavours will be added.* 
By using the workflow Pure has designed to expedite your migration to Pure CLoud Block Store (CBS), check the links below for detailed guides:
[AWS Migration with  Pure Cloud Block Store](https://support.purestorage.com/Pure_Cloud_Block_Store/VMware_VM_Migratation_to_AWS_with_Cloud_Block_Store_and_AWS_Application_Migration_Services)


The script will achieve the following:
 - Install required packages. 
 - Apply iSCSi and multipath best practice configuration. 
 - Connect to CBS and create a host. 
 - Provision the storage by cloning the replicated data volume. 
 - Create iSCSi initiator and discover the connected volume. 
 - Mount the volume

### Varaible

A couple of variables required before running the script.

`CBS_MNGMT_IP` -- The floating managemnt IP for Cloud Block Store.

`SNAPSHOT` -- Get the name of a recent replicated snapshot. You can get this from CBS in **Protection** > **Protection Groups** > **Target Protection Group Snapshot**

`DATA_VOLUME_PATH` -- Enter where you want to mount the data volume

 