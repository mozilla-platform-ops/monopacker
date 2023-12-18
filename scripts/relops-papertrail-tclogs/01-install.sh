#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

## using remote-syslog2 (recommended by PT)
# - issues
#    - no service...

# cd /tmp
# wget https://github.com/papertrail/remote_syslog2/releases/download/v0.21/remote-syslog2_0.21_amd64.deb
# sudo dpkg -i remote-syslog*.deb

## using systemd & ncat (used in ronin-puppet)

# nmap provides ncat
apt update
apt install -y ncat

export SERVICE_FILE=/etc/systemd/system/papertrail.service
export UNITS_TO_MONITOR="generic-worker"

# source secrets file
. /etc/relops/relops_papertrail_secrets

cat << EOF >> $SERVICE_FILE
[Unit]
Description=Papertrail
After=systemd-journald.service
Requires=systemd-journald.service
[Service]
ExecStart=/bin/sh -c "journalctl $UNITS_TO_MONITOR -f | ncat --ssl $PAPERTRAIL_HOST $PAPERTRAIL_PORT"
TimeoutStartSec=0
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target

EOF

# reload systemctl so it knows about config
systemctl daemon-reload

# enable the service on boot
systemctl enable papertrail

# TODO: start also? can verify it's format is correct...
# - shouldn't be any output on builder (w-m is not started)
systemctl start papertrail