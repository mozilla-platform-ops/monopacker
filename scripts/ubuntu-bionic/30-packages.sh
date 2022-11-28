#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

retry apt-get update
retry apt-get upgrade -y

# docker wants these
retry apt-get install -y \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

MISC_PACKAGES=()
MISC_PACKAGES+=(zstd python3-pip jq)
# docker-worker needs this for unpacking lz4 images
MISC_PACKAGES+=(liblz4-tool)

# misc
retry apt-get install -y ${MISC_PACKAGES[@]}

# Remove apport because it prevents obtaining crashes from containers
# and because it may send data to Canonical.
apt-get purge -y apport
