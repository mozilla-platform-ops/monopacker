#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# taken from https://github.com/taskcluster/community-tc-config/blob/main/imagesets/generic-worker-ubuntu-22-04/bootstrap.sh

# place a new worker unit file that is required by the graphical target
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
RequiredBy=graphical.target
EOF

# Installs the v4l2loopback kernel module
# used for the video device, and vkms
# required by Wayland
retry apt-get install -y linux-modules-extra-$(uname -r)
# needed for mutter to work with DRM rather than falling back to X11
grep -Fx vkms /etc/modules || echo vkms >> /etc/modules
# disable udev rule that tags platform-vkms with "mutter-device-ignore"
# ENV{ID_PATH}=="platform-vkms", TAG+="mutter-device-ignore"
sed '/platform-vkms/d' /lib/udev/rules.d/61-mutter.rules > /etc/udev/rules.d/61-mutter.rules

# podman installed in non-gui
retry apt-get install -y ubuntu-desktop ubuntu-gnome-desktop

# vnc configuration omitted
# - see https://github.com/taskcluster/community-tc-config/blob/5431d9f72f52eeb2bb232dcac55ad399f747ac6a/imagesets/generic-worker-ubuntu-22-04-staging/bootstrap.sh
