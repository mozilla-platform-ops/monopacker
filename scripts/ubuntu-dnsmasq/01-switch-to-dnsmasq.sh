#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# install dnsmasq before disabling systemd-resolved, because we need working
# dns to do so
apt-get install -y dnsmasq
# disable systemd-resolved
systemctl stop systemd-resolved
systemctl disable systemd-resolved
# remove symlink to systemd-resolved's resolv.conf; replace it with a version
# that points at the dnsmasq server that's about to start up
rm /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "server=8.8.8.8" >> /etc/dnsmasq.conf
systemctl start dnsmasq
systemctl enable dnsmasq
