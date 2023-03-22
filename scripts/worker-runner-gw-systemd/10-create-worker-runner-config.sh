#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

worker_runner_config="/etc/start-worker.yml"

# docker-worker config for reference 
#
# cat << EOF > "${worker_runner_config}"
# provider:
#     providerType: ${CLOUD}
# worker:
#     implementation: docker-worker
#     path: "${docker_worker_code}"
#     configPath: "${docker_worker_config}"
# # becomes part of docker-worker config
# workerConfig:
#     ed25519SigningKeyLocation: "${taskcluster_secrets_dir}/worker_ed25519_cot_key"
#     ssl:
#         certificate: "${taskcluster_secrets_dir}/worker_livelog_tls_cert"
#         key: "${taskcluster_secrets_dir}/worker_livelog_tls_key"
# EOF

# taken from https://github.com/mozilla-platform-ops/ronin_puppet/blob/master/modules/linux_generic_worker/templates/worker-runner-config.yml.erb

cat << EOF > "${worker_runner_config}"
cacheOverRestarts: true
getSecrets: false
provider:
    providerType: ${CLOUD}
worker:
    implementation: generic-worker
    path: /home/ubuntu/generic-worker/generic-worker
    configPath: /home/ubuntu/generic-worker/generic-worker.config
EOF