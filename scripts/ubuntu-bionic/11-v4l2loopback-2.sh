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

if [[ "$BUILD_V4L2LOOPBACK" ]]; then
    # This is for Ubuntu 18.04 in GCP. We have to build the module, otherwise it will not work.
    V4L2LOOPBACK_VERSION=${V4L2LOOPBACK_VERSION:-0.12.5}
    git clone -b v$V4L2LOOPBACK_VERSION https://github.com/umlaeute/v4l2loopback /usr/src/v4l2loopback-$V4L2LOOPBACK_VERSION
    # Edit the file `v4l2looback.c` and change the `MAX_DEVICES` definition to `100`
    # (NOTE: ignore the comments about overriding it in a `make` invocation; this isn't possible via dkms)
    sed -i -e "s/# *define MAX_DEVICES *[0-9]*/# define MAX_DEVICES $NUM_LOOPBACK_VIDEO_DEVICES/g" /usr/src/v4l2loopback-$V4L2LOOPBACK_VERSION/v4l2loopback.c
    dkms install -m v4l2loopback -v $V4L2LOOPBACK_VERSION
fi

if [[ "$CLOUD" == "google" ]]; then
    # Required in GCP.
    apt-get install linux-modules-extra-gcp -y
fi

# Configure video loopback devices
echo "options v4l2loopback devices=$NUM_LOOPBACK_VIDEO_DEVICES" > /etc/modprobe.d/v4l2loopback.conf
echo "videodev" | tee --append /etc/modules
echo "v4l2loopback" | tee --append /etc/modules

# test the presence of the required modules

modprobe videodev
lsmod | grep videodev

modprobe v4l2loopback
lsmod | grep v4l2loopback
ls -la /dev/video*
echo $NUM_LOOPBACK_VIDEO_DEVICES
test -e /dev/video$((NUM_LOOPBACK_VIDEO_DEVICES - 1))
