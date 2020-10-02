#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# https://github.com/moby/libnetwork/issues/1090
retry apt install -y iptables-persistent
iptables -I INPUT -m conntrack --ctstate INVALID -j DROP
iptables-save > /etc/iptables/rules.v4
