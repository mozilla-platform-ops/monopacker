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

# TODO: use helper functions
sudo apt update
sudo apt install rsyslog-gnutls -y

export RSYSLOG_FILE=/etc/rsyslog.conf

cat << EOF >> $RSYSLOG_FILE

# papertrail config
\$DefaultNetstreamDriverCAFile /etc/papertrail-bundle.pem
\$ActionSendStreamDriver gtls
\$ActionSendStreamDriverMode 1
\$ActionSendStreamDriverAuthMode x509/name
\$ActionSendStreamDriverPermittedPeer *.papertrailapp.com

EOF

# append the secret line to rsyslog.conf
# - placed by monopacker secrets system
cat /etc/relops/rsyslog_papertrail_line >> $RSYSLOG_FILE

# add a newline
cat << EOF >> $RSYSLOG_FILE

EOF

# restart service (or wait for new instances to boot up?)
# TOOD: remove/comment when testing is done
sudo service rsyslog restart