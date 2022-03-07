
#!/bin/bash 

#To run this script without using the ubuntu-user-data, you need to pass the following arguments in order. 
# ./ubuntu-post-migration.sh $CBS_MNGMT_IP $SNAPSHOT $DATA_VOLUME_PATH  
# For more details, visit https://github.com/PureStorage-OpenConnect/cloudblockstore-scripts

# Update and install required packages 
sudo apt update 
sudo apt upgrade -y
sudo apt install open-iscsi -y
sudo apt install lsscsi -y
sudo apt install jq -y


# mutlipath and iscsi best practices configuration
sudo service iscsid start
sudo /etc/init.d/open-iscsi restart

# Increase number of iscsi sessions per connection
sudo sed -i 's/^\(node\.session\.nr_sessions\s*=\s*\).*$/\132/' /etc/iscsi/iscsid.conf

# Change iscsi service to start automatically on boot
sudo sed -e '/^node.startup/s/manual/automatic/g' -i /etc/iscsi/iscsid.conf



sudo sed -e 's/^#*/#/g' -i /etc/multipath.conf

sudo cat << EOF >> /etc/multipath.conf
defaults {
       polling_interval      10
}
devices {
       device {
              vendor                "PURE"
              product               "FlashArray"
              path_selector         "queue-length 0"
              path_grouping_policy  group_by_prio
              path_checker          tur
              fast_io_fail_tmo      10
              dev_loss_tmo          60
              no_path_retry         queue
              hardware_handler      "1 alua"
              prio                  alua
              failback              immediate
      }
}
EOF




sudo service multipathd restart

# Get IQN
IQN=$( sudo grep InitiatorName /etc/iscsi/initiatorname.iscsi | awk -F= '{ print $2 }')
IQN=`echo $IQN | sed 's/ *$//g'`

# Generate api token
CBS_API_TOKEN=$(curl -s -k -X POST -H "Content-Type: application/json" -d '{"username": "pureuser","password": "pureuser"}' 'https://'$1'/api/1.19/auth/apitoken')

# Create a session
curl -s -k -H "Content-Type:application/json" -X POST -k -d "$CBS_API_TOKEN" 'https://'$1'/api/1.19/auth/session' -c ./cookies 

# Get iscsi interface ip
ISCSI_CBS_C0=$(curl -s -k --cookie ./cookies -X GET 'https://'$1'/api/1.19/network/ct0.eth2' -H 'Content-Type: application/json' | jq --raw-output '.address')


# Create a host 
HOSTNAME=$(hostname)
curl -s -k --cookie ./cookies -X POST 'https://'$1'/api/1.19/host/'$HOSTNAME'' -H 'Content-Type: application/json' -d "$(cat <<EOF
{
  "iqnlist": ["$IQN"]
}
EOF
)"


# Clone the Target 2 to a volume 

curl -s -k --cookie ./cookies  -H "Content-Type:application/json" -X POST 'https://'$1'/api/1.19/volume/clone_data01'  -d "$(cat <<EOF
{
  "source": "$2"
}
EOF
)"

# Conenct cloned volume to the created host 
curl -s -k --cookie ./cookies -H "Content-Type:application/json" -X POST 'https://'$1'/api/1.19/host/'$HOSTNAME'/volume/clone_data01' 


# iscsi initiator configuratione 
sudo iscsiadm -m iface -I iscsi0 -o new
sudo iscsiadm -m discovery -t st -p $ISCSI_CBS_C0:3260
sudo iscsiadm -m node --login
sudo iscsiadm -m node -L automatic



# mount volume
sudo mkdir $3
DISK=$(sudo multipath -ll | awk '{print $1;exit}')
sudo mount /dev/mapper/$DISK $3
