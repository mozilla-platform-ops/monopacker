#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# from https://docs.taskcluster.net/docs/reference/workers/worker-runner/deployment

# place systemd unit file
cat << EOF > /etc/systemd/system/generic-worker.service
[Unit]
Description=Start TC worker

[Service]
Type=simple
ExecStart=/usr/local/bin/start-worker /etc/start-worker.yml
# log to console to make output visible in cloud consoles, and syslog for ease of
# redirecting to external logging services
StandardOutput=syslog+console
StandardError=syslog+console
User=ubuntu
WorkingDirectory=~

[Install]
WantedBy=multi-user.target
EOF

systemctl enable generic-worker
