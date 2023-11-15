#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

worker_runner_config="/etc/start-worker.yml"

# taken from https://github.com/mozilla-platform-ops/ronin_puppet/blob/master/modules/linux_generic_worker/templates/worker-runner-config.yml.erb

cat << EOF > "${worker_runner_config}"
provider:
    providerType: ${CLOUD}
worker:
    implementation: generic-worker
    path: /home/ubuntu/generic_worker/generic-worker
    configPath: /home/ubuntu/generic_worker/generic-worker.config
EOF
