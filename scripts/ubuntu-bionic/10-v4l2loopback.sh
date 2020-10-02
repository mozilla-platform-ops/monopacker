#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

## Install the v4l2loopback out-of-tree kernel module at the given version, with the given number of devices enabled.  The
## number of devices dictates the number of parallel jobs The worker can run that use the driver.

V4L2LOOPBACK_VERSION=0.12.5
NUM_DEVICES=100

git clone -b v$V4L2LOOPBACK_VERSION git://github.com/umlaeute/v4l2loopback /usr/src/v4l2loopback-$V4L2LOOPBACK_VERSION

# Edit the file `v4l2looback.c` and change the `MAX_DEVICES` definition to `100`
# (NOTE: ignore the comments about overriding it in a `make` invocation; this isn't possible via dkms)
sed -i -e "s/# *define MAX_DEVICES 8/# define MAX_DEVICES $NUM_DEVICES/g" /usr/src/v4l2loopback-$V4L2LOOPBACK_VERSION/v4l2loopback.c

dkms install -m v4l2loopback -v $V4L2LOOPBACK_VERSION

# Configure video loopback devices
echo "options v4l2loopback devices=$NUM_DEVICES" > /etc/modprobe.d/v4l2loopback.conf
echo "videodev" | tee --append /etc/modules
echo "v4l2loopback" | tee --append /etc/modules

# test the results

modprobe videodev
lsmod | grep videodev

modprobe v4l2loopback
lsmod | grep v4l2loopback
test -e /dev/video$((NUM_DEVICES - 1))
