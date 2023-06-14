#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

if ! $SETUP_V4L2LOOPBACK; then
    echo "Skipping v4l2loopback"
    exit
fi

#apt-get install v4l2loopback-dkms -y

if [[ "$FIX_KERNEL_VERSION_MISMATCH" ]]; then
    # Update & upgrade makes us install the kernel we need, then reboot for it to move over to this new version.
    apt update
    apt upgrade -y

    # Shutdown and wait forever; packer will consider this script to have finished and
    # start on the next script when it reconnects
    shutdown -r now
    while true; do sleep 1; done
fi
