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

# install fails without (on minimal ubuntu)
# sudo apt update
# sudo apt install -y libxml2

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

# attempt 1: failed due to asking for input
# install cuda from runfile
#   from https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=runfile_local
# wget https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_530.30.02_linux.run 
# sh cuda_12.1.0_530.30.02_linux.run

# attempt 2
# install cuda from network
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
# set DEBIAN_FRONTEND=noninteractive despite being set already in 'ubuntu-jammy' script?!?
# DEBIAN_FRONTEND=noninteractive \
sudo apt-get -y install cuda

# fix dkms issues (worked on started instance... figure out ordering)
# - header dir was full of broken symlinks for some reason... !?!?
# sudo dkms autoinstall