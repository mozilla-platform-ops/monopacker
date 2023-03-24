#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# rm -rf /usr/src/*

# Do one final package cleanup, just in case.
apt-get autoremove -y --purge
