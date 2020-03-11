#!/bin/bash

set -exv

# If we are an EC2 instance, use the internal amazon NTP service
if "$WORKER_RUNNER_PROVIDER" == "aws"; then
    mkdir -p /etc/systemd/timesyncd.conf.d

    cat > /etc/systemd/timesyncd.conf.d/timesyncd.conf <<EOF
[Time]
NTP=169.254.169.123
EOF

fi
