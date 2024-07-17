#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# TODO: test that TASKCLUSTER_VERSION is defined or exit 1

cd /usr/local/bin
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/generic-worker-multiuser-linux-${TC_ARCH}" > generic-worker
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/start-worker-linux-${TC_ARCH}" > start-worker
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/livelog-linux-${TC_ARCH}" > livelog
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/taskcluster-proxy-linux-${TC_ARCH}" > taskcluster-proxy
chmod a+x generic-worker start-worker taskcluster-proxy livelog