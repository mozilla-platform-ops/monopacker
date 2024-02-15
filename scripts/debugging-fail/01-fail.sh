#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# end helpers

# use for testing
#   e.g. monopacker build generic_translations_gcp --packer-args '-on-error=ask'
# 
exit 1