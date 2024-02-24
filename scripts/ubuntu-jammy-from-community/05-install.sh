#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

#
# taken from https://github.com/taskcluster/community-tc-config/blob/main/imagesets/generic-worker-ubuntu-22-04/bootstrap.sh
#

retry apt-get update
DEBIAN_FRONTEND=noninteractive retry apt-get upgrade -yq
retry apt-get -y remove docker docker.io containerd runc
# build-essential is needed for running `go test -race` with the -vet=off flag as of go1.19
retry apt-get install -y apt-transport-https ca-certificates curl software-properties-common gzip python3-venv build-essential

# install docker
retry curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
retry apt-get update
retry apt-get install -y docker-ce docker-ce-cli containerd.io
retry docker run hello-world

# removed kvm vmware backdoor

cd /usr/local/bin
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/generic-worker-multiuser-linux-${TC_ARCH}" > generic-worker
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/start-worker-linux-${TC_ARCH}" > start-worker
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/livelog-linux-${TC_ARCH}" > livelog
retry curl -fsSL "https://github.com/taskcluster/taskcluster/releases/download/v${TASKCLUSTER_VERSION}/taskcluster-proxy-linux-${TC_ARCH}" > taskcluster-proxy
chmod a+x generic-worker start-worker taskcluster-proxy livelog

mkdir -p /etc/generic-worker
mkdir -p /var/local/generic-worker
mkdir -p /etc/taskcluster/secrets/
/usr/local/bin/generic-worker --version
/usr/local/bin/generic-worker new-ed25519-keypair --file /etc/generic-worker/ed25519_key

# ensure host 'taskcluster' resolves to localhost
echo 127.0.1.1 taskcluster >> /etc/hosts

# configure generic-worker to run on boot
# AJE: changed RequiredBy to multi-user
cat > /lib/systemd/system/worker.service << EOF
[Unit]
Description=Start TC worker

[Service]
Type=simple
ExecStart=/usr/local/bin/start-worker /etc/start-worker.yml
# log to console to make output visible in cloud consoles, and syslog for ease of
# redirecting to external logging services
StandardOutput=syslog+console
StandardError=syslog+console
User=root

[Install]
RequiredBy=multi-user.target
EOF

cat > /etc/start-worker.yml << EOF
provider:
    providerType: ${CLOUD}
worker:
    implementation: generic-worker
    path: /usr/local/bin/generic-worker
    configPath: /etc/generic-worker/config
cacheOverRestarts: /etc/start-worker-cache.json
EOF

systemctl enable worker

# install podman for d2g functionality
# - removed desktop packages, now in '...-gui' script dir
retry apt-get install -y podman

# set podman registries conf
(
  echo '[registries.search]'
  echo 'registries=["docker.io"]'
) >> /etc/containers/registries.conf

# omitting /etc/cloud/cloud.cfg.d/01_network_renderer_policy.cfg tweaks
