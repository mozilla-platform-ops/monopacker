#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# steps from https://papertrailapp.com/systems/setup?type=system&platform=unix#unix-manual

sudo wget -O /etc/papertrail-bundle.pem \
  https://papertrailapp.com/tools/papertrail-bundle.pem


sudo apt update
sudo apt install rsyslog-gnutls -y

cat << EOF >> /etc/rsyslog.conf
$DefaultNetstreamDriverCAFile /etc/papertrail-bundle.pem
$ActionSendStreamDriver gtls
$ActionSendStreamDriverMode 1
$ActionSendStreamDriverAuthMode x509/name
$ActionSendStreamDriverPermittedPeer *.papertrailapp.com

EOF

# append the secret line to rsyslog.conf
# - placed by monopacker secrets system
cat /etc/relops/rsyslog_papertrail_line >> /etc/rsyslog.conf

# restart service (or wait for new instances to boot up?)
# TOOD: remove/comment when testing is done
sudo service rsyslog restart