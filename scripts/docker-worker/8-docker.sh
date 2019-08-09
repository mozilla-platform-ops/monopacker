#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# per https://docs.docker.com/install/linux/docker-ce/ubuntu/

retry curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

retry apt-get update

# FIXME: add versioning
retry apt-get install -y docker-ce docker-ce-cli containerd.io

systemctl daemon-reload
systemctl enable docker.service

# don't start docker, this is the base image
