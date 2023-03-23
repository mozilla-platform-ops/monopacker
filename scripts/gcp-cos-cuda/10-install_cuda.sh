#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# from https://cloud.google.com/container-optimized-os/docs/how-to/run-gpus#install
sudo cos-extensions install gpu