#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

docker --version

# Versions for sidecar containers

# Pull images used for sidecar containers
retry docker pull taskcluster/taskcluster-proxy:v$TASKCLUSTER_VERSION

retry docker pull taskcluster/livelog:v$TASKCLUSTER_VERSION

dind_service_version=4.1
retry docker pull taskcluster/dind-service:v$dind_service_version

relengapi_proxy_version=2.3.1
retry docker pull taskcluster/relengapi-proxy:$relengapi_proxy_version
