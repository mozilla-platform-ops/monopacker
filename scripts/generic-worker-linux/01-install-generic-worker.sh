#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# Version numbers
GENERIC_WORKER_VERSION=$TASKCLUSTER_VERSION
LIVELOG_VERSION='v1.1.0'
TASKCLUSTER_PROXY_VERSION='v5.1.0'

# install generic-worker into /home/ubuntu/generic-worker
mkdir -p /home/ubuntu/generic-worker
cd /home/ubuntu/generic-worker
retry curl -L "https://github.com/taskcluster/taskcluster/releases/download/${GENERIC_WORKER_VERSION}/generic-worker-simple-linux-amd64" > generic-worker
retry curl -L "https://github.com/taskcluster/livelog/releases/download/${LIVELOG_VERSION}/livelog-linux-amd64" > livelog
retry curl -L "https://github.com/taskcluster/taskcluster-proxy/releases/download/${TASKCLUSTER_PROXY_VERSION}/taskcluster-proxy-linux-amd64" > taskcluster-proxy
chmod a+x generic-worker taskcluster-proxy livelog
chown -R ubuntu:ubuntu /home/ubuntu/generic-worker
./generic-worker --version
./generic-worker new-ed25519-keypair --file ed25519.key
