#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# see https://cloud.sylabs.io/ for more info
# steps from https://docs.sylabs.io/guides/2.6/user-guide/quick_start.html#quick-installation-steps

VERSION_TAG="v3.1.1"

# pre-reqs
sudo apt-get update && \
    sudo apt-get install \
    python \
    dh-autoreconf \
    build-essential \
    libarchive-dev

# get client and checkout appropriate tag
git clone https://github.com/sylabs/singularity.git
cd singularity
git fetch --all
git checkout "${VERSION_TAG}"

# configure, build, and install
./autogen.sh
./configure --prefix=/usr/local
make
sudo make install

# test
singularity --version