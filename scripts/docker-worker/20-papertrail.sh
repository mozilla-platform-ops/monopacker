#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# Get recent CA bundle for papertrail
retry curl -s -o /etc/papertrail-bundle.pem https://papertrailapp.com/tools/papertrail-bundle.pem
md5=`md5sum /etc/papertrail-bundle.pem | awk '{ print $1 }'`
if [ "$md5" != "2c43548519379c083d60dd9e84a1b724" ]; then
    echo "md5 for papertrail CA bundle does not match"
    exit -1
fi
