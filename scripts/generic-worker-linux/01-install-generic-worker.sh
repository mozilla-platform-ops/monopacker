#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# Version numbers
GENERIC_WORKER_VERSION=$TASKCLUSTER_VERSION
LIVELOG_VERSION='v1.1.0'
TASKCLUSTER_PROXY_VERSION='v5.1.0'

# install generic-worker into /home/ubuntu/generic_worker
mkdir -p /home/ubuntu/generic_worker
cd /home/ubuntu/generic_worker
retry curl -L "https://github.com/taskcluster/taskcluster/releases/download/v${GENERIC_WORKER_VERSION}/generic-worker-insecure-linux-amd64" > generic-worker
retry curl -L "https://github.com/taskcluster/livelog/releases/download/${LIVELOG_VERSION}/livelog-linux-amd64" > livelog
retry curl -L "https://github.com/taskcluster/taskcluster-proxy/releases/download/${TASKCLUSTER_PROXY_VERSION}/taskcluster-proxy-linux-amd64" > taskcluster-proxy
chmod a+x generic-worker taskcluster-proxy livelog
chown -R ubuntu:ubuntu /home/ubuntu/generic_worker
./generic-worker --version
./generic-worker new-ed25519-keypair --file ed25519.key
