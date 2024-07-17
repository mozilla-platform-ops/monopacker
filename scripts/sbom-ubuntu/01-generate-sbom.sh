#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

#

# cd to /etc so that the SBOM is created there
cd /etc
# generate the sbom with monopacker env vars
/etc/monopacker/utils/monopacker_ubuntu_sbom.py -b $MONOPACKER_BUILDER_NAME -c $MONOPACKER_GIT_SHA