#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# from https://linuxize.com/post/how-to-install-yarn-on-ubuntu-18-04/
retry curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

apt-get update
# don't also download node
apt-get install -y --no-install-recommends yarn

yarn --version
