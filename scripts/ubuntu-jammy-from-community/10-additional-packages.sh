#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# add additional packages

MISC_PACKAGES=()
# essentials
MISC_PACKAGES+=(build-essential curl git gnupg-agent jq mercurial)
# python things
MISC_PACKAGES+=(python3-pip python3-certifi python3-psutil)
# zstd packages
MISC_PACKAGES+=(zstd python3-zstd)
# things helpful for apt
MISC_PACKAGES+=(apt-transport-https ca-certificates software-properties-common)
# docker-worker needs this for unpacking lz4 images, perhaps uneeded but shouldn't hurt
MISC_PACKAGES+=(liblz4-tool)
# random bits
MISC_PACKAGES+=(libhunspell-1.7-0 libhunspell-dev)

retry apt-get install -y ${MISC_PACKAGES[@]}
