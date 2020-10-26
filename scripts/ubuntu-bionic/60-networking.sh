#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# https://github.com/moby/libnetwork/issues/1090
retry apt install -y iptables-persistent
iptables -I INPUT -m conntrack --ctstate INVALID -j DROP
iptables-save > /etc/iptables/rules.v4
