#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

node_version=8.15.0
url=http://nodejs.org/dist/v$node_version/node-v$node_version-linux-x64.tar.gz

# Download and install node to the /usr/ directory
retry curl $url > /tmp/node-$node_version.tar.gz
tar xzf /tmp/node-$node_version.tar.gz -C /usr/local/ --strip-components=1

# test it out
node --version
