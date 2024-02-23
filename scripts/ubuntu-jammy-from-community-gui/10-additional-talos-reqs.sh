#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# needed for fxci talos/raptor tests

# wait for reboot step prior to this to complete
#  - https://developer.hashicorp.com/packer/docs/v1.9.x/provisioners/shell#handling-reboots
#  - monopacker doesn't support pause_before, so do manually
# sleep 90

#
# apt packages
#
retry apt-get install -y kmod linux-generic linux-headers-generic linux-headers-gcp \
  v4l2loopback-dkms llvm sox libxcb1 nodejs xvfb

# not working: linux-headers
# missing: lib32ncurses5 gstreamer


#
# enable v4loopback
#

# required on 22.04?
# 
# if [[ "$BUILD_V4L2LOOPBACK" ]]; then
#     # This is for Ubuntu 18.04 in GCP. We have to build the module, otherwise it will not work.
#     V4L2LOOPBACK_VERSION=${V4L2LOOPBACK_VERSION:-0.12.5}
#     git clone -b v$V4L2LOOPBACK_VERSION https://github.com/umlaeute/v4l2loopback /usr/src/v4l2loopback-$V4L2LOOPBACK_VERSION
#     # Edit the file `v4l2looback.c` and change the `MAX_DEVICES` definition to `100`
#     # (NOTE: ignore the comments about overriding it in a `make` invocation; this isn't possible via dkms)
#     sed -i -e "s/# *define MAX_DEVICES *[0-9]*/# define MAX_DEVICES $NUM_LOOPBACK_VIDEO_DEVICES/g" /usr/src/v4l2loopback-$V4L2LOOPBACK_VERSION/v4l2loopback.c
#     dkms install -m v4l2loopback -v $V4L2LOOPBACK_VERSION
# fi

# Required in GCP.
retry apt-get install linux-modules-extra-gcp -y

# Configure video loopback devices
echo "options v4l2loopback devices=$NUM_LOOPBACK_VIDEO_DEVICES" > /etc/modprobe.d/v4l2loopback.conf
echo "videodev" | tee --append /etc/modules
echo "v4l2loopback" | tee --append /etc/modules

# test the results

modprobe videodev
lsmod | grep videodev

modprobe v4l2loopback
lsmod | grep v4l2loopback
# currently failing... only 7 devices... /dev/video7
test -e /dev/video$((NUM_LOOPBACK_VIDEO_DEVICES - 1))

#
# configure audio loopback devices
#

# Configure audio loopback devices, with options enable=1,1,1...,1 index = 0,1,...,N
i=0
enable=''
index=''
while [ $i -lt $NUM_LOOPBACK_AUDIO_DEVICES ]; do
    enable="$enable,1"
    index="$index,$i"
    i=$((i + 1))
done
# slice off the leading `,` in each variable
enable=${enable:1}
index=${index:1}

echo "options snd-aloop enable=$enable index=$index" > /etc/modprobe.d/snd-aloop.conf
echo "snd-aloop" | tee --append /etc/modules

# test
modprobe snd-aloop
lsmod | grep snd_aloop
test -e /dev/snd/controlC$((NUM_LOOPBACK_AUDIO_DEVICES - 1))


#
# directories expected by talos
#
dirs="/builds /builds/slave /builds/slave/talos-data /builds/slave/talos-data/talos \
  /builds/git-shared /builds/hg-shared /builds/tooltool_cache"

mkdir -p $dirs
# task user changes... set to root for now
chown -R root:root $dirs
chmod -R 0777 $dirs

# test
ls -lad $dirs