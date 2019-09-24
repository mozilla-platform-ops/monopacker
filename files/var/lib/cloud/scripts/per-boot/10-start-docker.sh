#!/bin/bash

set -ex

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh
log_execution $0

systemctl start docker.service
