#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

echo "new kernel: $(uname -r)"

# verify kernel crash dump is ready to go
kdump-config show
