#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# Get recent CA bundle for papertrail
retry curl -s -o /etc/papertrail-bundle.pem https://papertrailapp.com/tools/papertrail-bundle.pem
md5=`md5sum /etc/papertrail-bundle.pem | awk '{ print $1 }'`
if [ "$md5" != "2c43548519379c083d60dd9e84a1b724" ]; then
    echo "md5 for papertrail CA bundle does not match"
    exit -1
fi

retry apt install -y rsyslog-gnutls

echo "Setting +x and importing papertrail host"
set +x
export PAPERTRAIL_HOST=$(cat /etc/taskcluster/secrets/worker_papertrail_dest)
set -x
echo "Resuming -x"

cat << EOF > /etc/rsyslog.d/0-taskcluster.conf
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
*.info @@$PAPERTRAIL_HOST
EOF
