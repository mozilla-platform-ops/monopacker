#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# download docker-worker to /home/ubuntu/docker-worker
docker_worker_version="v201908071906"
retry curl -L -o /tmp/docker-worker.tgz "https://github.com/taskcluster/docker-worker/archive/${docker_worker_version}.tar.gz"
mkdir -p /home/ubuntu/docker-worker
tar xvf /tmp/docker-worker.tgz -C /home/ubuntu/docker-worker --strip-components 1

cat << EOF > /usr/local/bin/start-docker-worker
#!/bin/bash
set -exv
/usr/local/bin/start-worker /etc/worker-runner/start-worker.yml 2>&1 | logger --tag docker-worker
EOF
file /usr/local/bin/start-docker-worker
chmod +x /usr/local/bin/start-docker-worker

# install deps
cd /home/ubuntu/docker-worker
yarn install --frozen-lockfile

# worker runner config
mkdir -p /etc/worker-runner
cat << EOF > /etc/worker-runner/start-worker.yml
provider:
    providerType: aws-provisioner
worker:
    implementation: docker-worker
    path: /home/ubuntu/docker-worker
    configPath: /home/ubuntu/worker.cfg
EOF

cat << EOF > /etc/systemd/system/docker-worker.service
[Unit]
Description=Taskcluster docker worker
After=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/start-docker-worker /etc/worker-runner/start-worker.yml 2>&1 | logger --tag docker-worker
User=root

[Install]
RequiredBy=multiuser.target
EOF
