#!/bin/bash

# VARIABLES

CBS_MNGMT_IP=<enter-cbs-management-ip>     # i.e CBS_MNGMT_IP=172.23.2.180
SNAPSHOT=<enter-snapshot-name>             # i.e SNAPSHOT=flasharray-m20-1:cbs-aws-migration-policy.3.vvol-Linux-ubuntu/Data-a2e2d086
DATA_VOLUME_PATH=<enter-mount-path>        # i.e DATA_VOLUME_PATH=/mnt/data

sudo apt -y install git
sudo git clone https://github.com/PureStorage-OpenConnect/cloudblockstore-scripts
sudo chmod 700 /cloudblockstore-scripts/linux-migration/ubuntu-post-migration.sh

sudo sh /cloudblockstore-scripts/linux-migration/ubuntu-post-migration.sh $CBS_MNGMT_IP $SNAPSHOT $DATA_VOLUME_PATH > /tmp/pure-post-migration.log 2>&1