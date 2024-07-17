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
/etc/monopacker/utils/move_sbom_to_latest_artifact_name.py -b $MONOPACKER_BUILDER_NAME -c $MONOPACKER_GIT_SHA