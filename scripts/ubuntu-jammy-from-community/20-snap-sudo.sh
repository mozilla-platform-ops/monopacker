#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# to enable snap testing

# create group
groupadd snap_sudo

# add sudoers entry for the group
echo '%snap_sudo ALL=(ALL:ALL) NOPASSWD: /usr/bin/snap' | EDITOR='tee -a' visudo