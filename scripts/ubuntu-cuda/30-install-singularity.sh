#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# see https://cloud.sylabs.io/ for more info
# steps from https://docs.sylabs.io/guides/3.11/admin-guide/installation.html

# from official deb

# pre-reqs
sudo apt-get install -y \
   build-essential \
   libseccomp-dev \
   libglib2.0-dev \
   pkg-config \
   squashfs-tools \
   cryptsetup \
   runc \
   uidmap

# install deb
cd /tmp
wget https://github.com/sylabs/singularity/releases/download/v3.11.1/singularity-ce_3.11.1-jammy_amd64.deb
dpkg -i singularity-ce_3.11.1-jammy_amd64.deb
rm *.deb