#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

## vars
# TODO consolidate these into a globals files
# secrets
taskcluster_secrets_dir="/etc/taskcluster/secrets"

# docker-worker and
# worker-runner config
docker_worker_config="/etc/taskcluster/docker-worker/config.yml"
worker_runner_config="/etc/taskcluster/worker-runner/start-worker.yml"
worker_runner_state="/etc/taskcluster/worker-runner/state"

# worker-runner start-worker binary
worker_runner="/usr/local/bin/start-worker"

# download docker-worker to this dir
docker_worker_code="/home/ubuntu/docker-worker"

# from worker-runner download location
docker_worker_start_script="/usr/local/bin/start-docker-worker"
docker_worker_version="v201909022008"

retry curl -L -o /tmp/docker-worker.tgz "https://github.com/taskcluster/docker-worker/archive/${docker_worker_version}.tar.gz"
mkdir -p "${docker_worker_code}"
tar xvf /tmp/docker-worker.tgz -C "${docker_worker_code}" --strip-components 1

cat << EOF > "${docker_worker_start_script}"
#!/bin/bash
set -exv
${worker_runner} ${worker_runner_config} 2>&1 | logger --tag docker-worker
EOF
file "${docker_worker_start_script}"
chmod +x "${docker_worker_start_script}"

# install deps
cd "${docker_worker_code}"
yarn install --frozen-lockfile

mkdir -p "$(dirname ${docker_worker_config})"
mkdir -p "$(dirname ${worker_runner_config})"
cat << EOF > "${worker_runner_config}"
provider:
    providerType: aws-provisioner
worker:
    implementation: docker-worker
    path: "${docker_worker_code}"
    configPath: "${docker_worker_config}"
# becomes part of docker-worker config
workerConfig:
    # loopbacks should work
    deviceManagement:
        loopbackAudio:
            enabled: true
        loopbackVideo:
            enabled: true
    dockerWorkerPrivateKey: "${taskcluster_secrets_dir}/worker_cot_key"
    ed25519SigningKeyLocation: "${taskcluster_secrets_dir}/worker_ed25519_cot_key"
    ssl:
        certificate: "${taskcluster_secrets_dir}/worker_livelog_tls_cert"
        key: "${taskcluster_secrets_dir}/worker_livelog_tls_key"
    shutdown:
        enabled: false
        afterIdleSeconds: 0
cacheOverRestarts: "${worker_runner_state}"
EOF

cat << EOF > /etc/systemd/system/docker-worker.service
[Unit]
Description=Taskcluster docker worker
After=docker.service

[Service]
Type=simple
ExecStart=${docker_worker_start_script}
User=root

[Install]
RequiredBy=multi-user.target
EOF

systemctl enable docker-worker
