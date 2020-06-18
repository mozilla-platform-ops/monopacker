#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# use WORKER_RUNNER_VERSION, defaulting to TASKCLUSTER_VERSION
worker_runner_version=${WORKER_RUNNER_VERSION:-$TASKCLUSTER_VERSION}
if [ -n "$WORKER_RUNNER_RELEASE_FILE" ]; then
    mv "$WORKER_RUNNER_RELEASE_FILE" /usr/local/bin/start-worker
else
    retry curl -fsSL -o /usr/local/bin/start-worker https://github.com/taskcluster/taskcluster/releases/download/v${worker_runner_version}/start-worker-linux-amd64
fi
file /usr/local/bin/start-worker
chmod +x /usr/local/bin/start-worker
