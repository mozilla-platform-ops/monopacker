#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# hg

#
# setup robustcheckout
#

RC_PLUGIN="/etc/hgext/robustcheckout.py"
RC_URL="https://hg.mozilla.org/hgcustom/version-control-tools/raw-file/tip/hgext/robustcheckout/__init__.py"

mkdir /etc/hgext
chmod 0755 /etc/hgext
chown -R root:root /etc/hgext

curl -o $RC_PLUGIN $RC_URL
chmod 0644 $RC_PLUGIN

cat << EOF > /etc/mercurial/hgrc
[extensions]
robustcheckout = $RC_PLUGIN
EOF

# test
hg --version
hg showconfig | grep robustcheckout
