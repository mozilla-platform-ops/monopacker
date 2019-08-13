#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

retry apt update
retry apt upgrade -y

# docker wants these
retry apt install -y \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

# misc
retry apt install -y \
  zstd \
  python-pip \
  jq

# Remove apport because it prevents obtaining crashes from containers
# and because it may send data to Canonical.
apt-get purge -y apport
