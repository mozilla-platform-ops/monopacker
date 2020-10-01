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

# use DOCKER_WORKER_VERSION, defaulting to TASKCLUSTER_VERSION
docker_worker_version=${DOCKER_WORKER_VERSION:-$TASKCLUSTER_VERSION}

# get the docker-worker tarball, either locally or from a TC release
if [ -n "$DOCKER_WORKER_RELEASE_FILE" ]; then
    mv "$DOCKER_WORKER_RELEASE_FILE" /tmp/docker-worker.tgz
else
    retry curl --fail -L -o /tmp/docker-worker.tgz "https://github.com/taskcluster/taskcluster/releases/download/v$docker_worker_version/docker-worker-x64.tgz"
fi
mkdir -p "${docker_worker_code}"
tar xf /tmp/docker-worker.tgz -C "${docker_worker_code}" --strip-components 1
rm /tmp/docker-worker.tgz

cat << EOF > "${docker_worker_start_script}"
#!/bin/bash
set -exv
${worker_runner} ${worker_runner_config} 2>&1 | logger --tag docker-worker
EOF
file "${docker_worker_start_script}"
chmod +x "${docker_worker_start_script}"

mkdir -p "$(dirname ${docker_worker_config})"
mkdir -p "$(dirname ${worker_runner_config})"
cat << EOF > "${worker_runner_config}"
provider:
    providerType: ${CLOUD}
worker:
    implementation: docker-worker
    path: "${docker_worker_code}"
    configPath: "${docker_worker_config}"
# becomes part of docker-worker config
workerConfig:
    dockerWorkerPrivateKey: "${taskcluster_secrets_dir}/worker_cot_key"
    ed25519SigningKeyLocation: "${taskcluster_secrets_dir}/worker_ed25519_cot_key"
    ssl:
        certificate: "${taskcluster_secrets_dir}/worker_livelog_tls_cert"
        key: "${taskcluster_secrets_dir}/worker_livelog_tls_key"
EOF

if [ "$CLOUD" == "azure" ]; then
  extra_required_units="walinuxagent.service"
fi

cat << EOF > /etc/systemd/system/docker-worker.service
[Unit]
Description=Taskcluster docker worker
After=docker.service docker-worker-disk-setup.service $extra_required_units
Requires=docker.service docker-worker-disk-setup.service $extra_required_units

[Service]
Type=simple
ExecStart=${docker_worker_start_script}
User=root

[Install]
RequiredBy=multi-user.target
EOF

systemctl enable docker-worker
