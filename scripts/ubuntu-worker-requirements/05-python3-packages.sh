#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

retry apt-get install -y python3-pip

# do apt cleanup
apt-get autoremove -y --purge

# no deb available for this, install via pip3
pip3 install zstandard
