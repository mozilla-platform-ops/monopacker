#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# Do one final package cleanup, just in case.
apt autoremove -y --purge
