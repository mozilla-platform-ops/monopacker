#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

retry apt update
retry apt install -y dkms

## Install v4l2loopback
dpkg -i --force-confnew /var/kernel/v4l2loopback-dkms*.deb

# Configure audio loopback devices
echo "options snd-aloop enable=1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 index=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31" > /etc/modprobe.d/snd-aloop.conf
echo "snd-aloop" | tee --append /etc/modules

# Configure video loopback devices
echo "options v4l2loopback devices=32" > /etc/modprobe.d/v4l2loopback.conf
echo "videodev" | tee --append /etc/modules
echo "v4l2loopback" | tee --append /etc/modules


