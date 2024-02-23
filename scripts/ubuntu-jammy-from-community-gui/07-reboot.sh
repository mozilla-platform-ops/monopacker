#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

#
# reboot to use the new kernel
#
# Shutdown and wait forever; packer will consider this script to have finished and
# start on the next script when it reconnects
shutdown -r now
#while true; do sleep 1; done
