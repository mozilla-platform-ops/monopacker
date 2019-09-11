#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

retry apt install -y rsyslog-gnutls

cat << EOF > /etc/rsyslog.d/0-docker-worker.conf
\$DefaultNetstreamDriverCAFile /etc/papertrail-bundle.pem # trust these CAs
\$ActionSendStreamDriver gtls # use gtls netstream driver
\$ActionSendStreamDriverMode 1 # require TLS
\$ActionSendStreamDriverAuthMode x509/name # authenticate by hostname
\$ActionSendStreamDriverPermittedPeer *.papertrailapp.com
\$ActionResumeInterval 10
\$ActionQueueSize 100000
\$ActionQueueDiscardMark 97500
\$ActionQueueHighWaterMark 80000
\$ActionQueueType LinkedList
\$ActionQueueFileName papertrailqueue
\$ActionQueueCheckpointInterval 100
\$ActionQueueMaxDiskSpace 2g
\$ActionResumeRetryCount -1
\$ActionQueueSaveOnShutdown on
\$ActionQueueTimeoutEnqueue 10
\$ActionQueueDiscardSeverity 0
*.* @@$PAPERTRAIL
EOF
