#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# install and configure taskcluster-worker-runner
worker_runner_version=$TASKCLUSTER_VERSION
retry curl -L -o /usr/local/bin/start-worker https://github.com/taskcluster/taskcluster/releases/download/${worker_runner_version}/start-worker-linux-amd64
file /usr/local/bin/start-worker
chmod +x /usr/local/bin/start-worker
