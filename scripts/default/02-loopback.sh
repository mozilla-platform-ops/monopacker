#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# Configure audio loopback devices
echo "snd-aloop" | sudo tee --append /etc/modules
echo "options snd-aloop enable=1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 index=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29" > /etc/modprobe.d/snd-aloop.conf

## Install v4l2loopback
retry apt-get install -y v4l2loopback-dkms
echo "v4l2loopback" | sudo tee --append /etc/modules
echo "options v4l2loopback devices=100" > /etc/modprobe.d/v4l2loopback.conf
