#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

#
# reboot to use the new resolver
#
shutdown -r now
# monopacker will detect that a reboot is done in this step (via name of the script)
# and pause before starting next step