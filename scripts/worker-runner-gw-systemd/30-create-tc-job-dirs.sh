#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# create directories used by taskcluster jobs
USER_DIR="/home/ubuntu"
DIR_LIST="${USER_DIR}/tasks ${USER_DIR}/caches ${USER_DIR}/downloads"

sudo mkdir -p ${DIR_LIST}
sudo chown -R ubuntu:ubuntu ${DIR_LIST}