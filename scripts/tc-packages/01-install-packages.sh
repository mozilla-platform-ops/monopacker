#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# update apt first
retry apt-get update

# docker wants these
retry apt-get install -y \
  build-essential \
  git \
  mercurial \
  python3-zstandard \
  python3-certifi \
  python3-psutil \
  zstd

# Do one final package cleanup, just in case.
apt-get autoremove -y --purge
