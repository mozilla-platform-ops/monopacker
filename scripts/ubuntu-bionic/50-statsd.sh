#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# Ubuntu 18 GCP workers require the use of pip3 instead of pip, so this checks for pip
# if it exists, we use that, if not, we use pip3.
if [[ -x "$(which pip)" ]] ; then
  pip install python-statsd
else
  pip3 install python-statsd
fi
