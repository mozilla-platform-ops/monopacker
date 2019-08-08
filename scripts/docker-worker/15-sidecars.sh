#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

docker --version

# Versions for sidecar containers
relengapi_proxy_version=2.3.1
taskcluster_proxy_version=5.1.0
livelog_version=4
dind_service_version=4.0
worker_runner_version=0.3.0

# Pull images used for sidecar containers
retry docker pull taskcluster/taskcluster-proxy:$taskcluster_proxy_version
retry docker pull taskcluster/livelog:v$livelog_version
retry docker pull taskcluster/dind-service:v$dind_service_version
retry docker pull taskcluster/relengapi-proxy:$relengapi_proxy_version
