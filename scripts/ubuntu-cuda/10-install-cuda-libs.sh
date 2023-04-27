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
sudo apt-get -y reinstall linux-headers-`uname -r` linux-gcp-headers-`uname -r | sed -r  s/-gcp//`

#
# install driver
#

# install cuda from network (runfile demands input and fails)
cd /tmp
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda
