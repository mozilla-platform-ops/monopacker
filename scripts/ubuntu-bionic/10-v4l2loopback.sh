#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

if ! $SETUP_V4L2LOOPBACK; then
    echo "Skipping v4l2loopback"
    exit
fi

apt-get install v4l2loopback-dkms -y

if [[ "$CLOUD" == "google" ]]; then
    apt-get install linux-modules-extra-gcp -y
fi

# Configure video loopback devices
echo "options v4l2loopback devices=$NUM_LOOPBACK_VIDEO_DEVICES" > /etc/modprobe.d/v4l2loopback.conf
echo "videodev" | tee --append /etc/modules
echo "v4l2loopback" | tee --append /etc/modules

# test the results

modprobe videodev
lsmod | grep videodev

modprobe v4l2loopback
lsmod | grep v4l2loopback
test -e /dev/video$((NUM_LOOPBACK_VIDEO_DEVICES - 1))
