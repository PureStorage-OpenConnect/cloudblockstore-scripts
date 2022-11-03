#!/bin/bash -xe

# The script will achieve the following:
# 1. Install required packages.
# 2. Apply iSCSi and multipath best practice configuration.
# 3. Connect to CBS and create a host. 
# 4. provision the storage 
# 5. Create iSCSi initiator and discover the connected volume
# 6. Mount the volume


#######################
## Enter you Environment Variables 
#######################


# Enter IP address or FQDN of Cloud Block Store
CBS_MNGMT_IP=<enter_IP_address>  #CBS_MNGMT_IP=10.0.1.108

# Enter the path where to mount the volume
DATA_VOLUME_PATH=/data

# Enter the Host Group Name 
HOSTGROUP=ASG-HGROUP

# Option #1# Enter the size of the volume
VOLSIZE=1000G

# Option #2# Connect the existed shared volume to the host
#VOLNAME=ASG-SHARED-VOLUME


# Update and install required packages 
sudo yum update -y 
sudo yum -y install iscsi-initiator-utils
sudo yum -y install lsscsi
sudo yum -y install device-mapper-multipath
sudo yum -y install jq


#######################
## Mutlipath and iscsi best practices configuration
#######################

sudo service iscsid start
sudo sed -i 's/^\(node\.session\.nr_sessions\s*=\s*\).*$/\132/' /etc/iscsi/iscsid.conf


sudo cat << EOF > /etc/udev/rules.d/99-pure-storage.rules 
# Recommended settings for Pure Storage FlashArray.cat 
# Use noop scheduler for high-performance solid-state storage
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/scheduler}="noop"
# Reduce CPU overhead due to entropy collection
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/add_random}="0"
# Spread CPU load by redirecting completions to originating CPU
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/rq_affinity}="2"
# Set the HBA timeout to 60 secondsi
ACTION=="add", SUBSYSTEMS=="scsi", ATTRS{model}=="FlashArray ", RUN+="/bin/sh -c 'echo 60 > /sys/$DEVPATH/device/timeout'"
EOF

sudo mpathconf --enable --with_multipathd y

sudo sed -e 's/^#*/#/g' -i /etc/multipath.conf

sudo cat << EOF >> /etc/multipath.conf
defaults {
       polling_interval 10
       user_friendly_names yes
       find_multipaths yes
}
devices {
       device {
               vendor                "PURE"
               path_selector         "queue-length 0"
               path_grouping_policy  group_by_prio
               path_checker          tur
               fast_io_fail_tmo      10
               no_path_retry         queue
               hardware_handler      "1 alua"
               prio                  alua
               failback              immediate
       }
}
EOF

sudo service multipathd restart

#######################
## CBS Operations 
#######################

# Generate api_token
CBS_API_TOKEN=$(curl -X POST -H "Content-Type: application/json" -k -d '{"username": "pureuser","password": "pureuser"}' 'https://'$CBS_MNGMT_IP'/api/1.19/auth/apitoken' | jq --raw-output .api_token)

#Exchange with x_auth_token
X_AUTH_TOKEN=$(curl -k -X POST 'https://'$CBS_MNGMT_IP'/api/2.11/login' -H 'api-token: '$CBS_API_TOKEN'' -i | grep x-auth-token | awk '{ print $2}')

# Get iscsi interface ip address 
ISCSI_CBS_C0=$(curl -k -X GET 'https://'$CBS_MNGMT_IP'/api/2.11/network-interfaces/' -H 'x-auth-token: '$X_AUTH_TOKEN'' \
| jq --raw-output '[.items[] | select(.services[] | contains("iscsi")).eth.address] | first')


# Create a hostgroup
curl -X POST 'https://'$CBS_MNGMT_IP'/api/2.11/host-groups' -H 'x-auth-token: '$X_AUTH_TOKEN'' -k -d '{"names": "$HOSTGROUP"}'


# Get the Instance ID  
export INITNAME=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Get IQN
export IQN=$(grep InitiatorName /etc/iscsi/initiatorname.iscsi | awk -F= '{ print $2 }')

# Create a host 
curl -X POST 'https://'$CBS_MNGMT_IP'/api/2.11/hosts' -H 'x-auth-token: '$X_AUTH_TOKEN'' -k -d '{"names": "$INITNAME", "iqns": ["$IQN"]}'

# Add host to hostgroup
curl -X POST 'https://'$CBS_MNGMT_IP'/api/2.11/host-groups/hosts?group_names='$HOSTGROUP'&member_names='$INITNAME'' -H 'x-auth-token: '$X_AUTH_TOKEN'' -k

## Option 1 ##
# Create a volume
curl -k -X POST 'https://'$CBS_MNGMT_IP'/api/2.11/volumes?names='$INITNAME'&provisioned='$VOLSIZE'' -H 'x-auth-token: '$X_AUTH_TOKEN''

sleep 10

# Conenct the volume to the host 
curl -k -X POST 'https://'$CBS_MNGMT_IP'/api/2.11/connections?host_names='$INITNAME'&volume_names='$INITNAME'' -H 'x-auth-token: '$X_AUTH_TOKEN''

## Option 2 ##
# Connect the existed shared volume to the host
#curl -k -X POST 'https://'$CBS_MNGMT_IP'/api/2.11/connections?host_names='$INITNAME'&volume_names='$VOLNAME'' -H 'x-auth-token: '$X_AUTH_TOKEN''


#######################
## Initialize and mount the volume 
#######################

# iscsi initiator configuratione 
sudo iscsiadm -m iface -I iscsi0 -o new
sudo iscsiadm -m discovery -t st -p $ISCSI_CBS_C0:3260
sudo iscsiadm -m node --login
sudo iscsiadm -m node -o update -n node.startup -v automatic

sleep 10

# Create filesystem and mount Volume
sudo mkdir $DATA_VOLUME_PATH
disk=`sudo multipath -ll|awk '{print $1;exit}'`
sudo mkfs.ext4 /dev/mapper/$disk

sleep 10

sudo mount /dev/mapper/$disk $DATA_VOLUME_PATH