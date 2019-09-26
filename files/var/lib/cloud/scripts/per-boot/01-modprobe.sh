#!/bin/bash

set -ex

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh
log_execution $0

# Initialize video and sound loopback modules
modprobe --force-vermagic v4l2loopback
modprobe snd-aloop
# Create dependency file
depmod
