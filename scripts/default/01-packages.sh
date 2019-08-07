#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# docker wants these
retry apt-get update
retry apt-get install -y \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

# misc
retry apt-get install -y \
  zstd \
  python-pip \
  jq

# Remove apport because it prevents obtaining crashes from containers
# and because it may send data to Canonical.
apt-get purge -y apport
