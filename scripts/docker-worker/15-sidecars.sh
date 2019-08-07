#!/bin/bash

set -exv

docker --version

# Versions for sidecar containers
relengapi_proxy_version=2.3.1
taskcluster_proxy_version=5.1.0
livelog_version=4
dind_service_version=4.0
worker_runner_version=0.3.0

# Pull images used for sidecar containers
docker pull taskcluster/taskcluster-proxy:$taskcluster_proxy_version
docker pull taskcluster/livelog:v$livelog_version
docker pull taskcluster/dind-service:v$dind_service_version
docker pull taskcluster/relengapi-proxy:$relengapi_proxy_version
