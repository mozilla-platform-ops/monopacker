#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

## vars
# TODO consolidate these into a globals files
# secrets
taskcluster_secrets_dir="/etc/taskcluster/secrets"

# generic-worker and
# worker-runner config
generic_worker_config="/etc/taskcluster/generic-worker/config.yml"
worker_runner_config="/etc/taskcluster/worker-runner/start-worker.yml"
worker_runner_state="/etc/taskcluster/worker-runner/state"

# worker-runner start-worker binary
worker_runner="/usr/local/bin/start-worker"

# download generic-worker binary directly
generic_worker_version="v16.0.0"
livelog_version='v1.1.0'
taskcluster_proxy_version='v5.1.0'
generic_worker_dir="/home/ubuntu/generic-worker"
generic_worker_binary="${generic_worker_dir}/generic-worker"

mkdir -p "${generic_worker_dir}"
retry curl -L -o "${generic_worker_binary}" "https://github.com/taskcluster/generic-worker/releases/download/${generic_worker_version}/generic-worker-multiuser-linux-amd64"
retry curl -L -o "${generic_worker_dir}/livelog" "https://github.com/taskcluster/livelog/releases/download/${livelog_version}/livelog-linux-amd64"
retry curl -L -o "${generic_worker_dir}/taskcluster-proxy" "https://github.com/taskcluster/taskcluster-proxy/releases/download/${taskcluster_proxy_version}/taskcluster-proxy-linux-amd64"

chmod a+x "${generic_worker_binary}" "${generic_worker_dir}/livelog" "${generic_worker_dir}/taskcluster-proxy"
chown -R ubuntu:ubuntu "${generic_worker_dir}"
"${generic_worker_binary}" --version
"${generic_worker_binary}" new-ed25519-keypair --file "${generic_worker_dir}/ed25519.key"

generic_worker_start_script="/usr/local/bin/start-generic-worker"
cat << EOF > "${generic_worker_start_script}"
#!/bin/bash
set -exv
${worker_runner} ${worker_runner_config} 2>&1 | logger --tag generic-worker
EOF
file "${generic_worker_start_script}"
chmod +x "${generic_worker_start_script}"

mkdir -p "$(dirname ${generic_worker_config})"
mkdir -p "$(dirname ${worker_runner_config})"
cat << EOF > "${worker_runner_config}"
provider:
    providerType: ${WORKER_RUNNER_PROVIDER}
worker:
    implementation: generic-worker
    path: "${generic_worker_binary}"
    configPath: "${generic_worker_config}"
# becomes part of generic-worker config
workerConfig:
    ed25519SigningKeyLocation: "${taskcluster_secrets_dir}/worker_ed25519_cot_key"
cacheOverRestarts: "${worker_runner_state}"
EOF

cat << EOF > /etc/systemd/system/generic-worker.service
[Unit]
Description=Taskcluster generic worker

[Service]
Type=simple
ExecStart=${generic_worker_start_script}
User=root

[Install]
RequiredBy=multi-user.target
EOF

systemctl enable generic-worker
