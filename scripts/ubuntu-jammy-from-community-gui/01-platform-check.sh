#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# taken from https://github.com/taskcluster/community-tc-config/blob/main/imagesets/generic-worker-ubuntu-22-04/bootstrap.sh

# ensure we're on a platform that's supported
case "$(uname -m)" in
  x86_64)
    ARCH=amd64
    ;;
  aarch64)
    ARCH=arm64
    ;;
  *)
    echo "Unsupported architecture '$(uname -m)' - currently bootstrap.sh only supports architectures x86_64 and aarch64" >&2
    exit 64
    ;;
esac
