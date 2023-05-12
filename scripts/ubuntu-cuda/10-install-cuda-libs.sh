#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

#
# prepare
#

# problem: broken symlinks in directory below
#   ls -la ls /usr/src/linux-headers-5.15.0-1030-gcp
# fix:
#   sudo apt reinstall linux-gcp-headers-5.15.0-1030
#
# ensure kernel headers are present so dkms works
# - had issue where there were broken symlinks

# fix 1:
#  not needed now? package name changed
#      linux-gcp-headers-`uname -r | sed -r  s/-gcp//`

# fix 2
# now: linux-gcp-5.19-headers-5.19.0-1021
# `uname -r`: 5.19.0-1021-gcp
version=`uname -r`
version_minus_dash_gcp=`uname -r | sed -r  s/-gcp//`
short_version=`uname -r | cut -d "." -f1,2`
pkg_name="linux-gcp-${short_version}-headers-${version_minus_dash_gcp}"

sudo apt-get update
sudo apt-get -y reinstall linux-headers-gcp linux-headers-`uname -r` ${pkg_name}

# TODO: install future kernel headers (latest in `dpkg --list 'linux-image*'` output)
#       in addition to current (uname -r)?
#         - not needed as we're compiling on what's running?


#
# install driver
#

# install cuda from network (runfile demands input and fails)
cd /tmp
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda
