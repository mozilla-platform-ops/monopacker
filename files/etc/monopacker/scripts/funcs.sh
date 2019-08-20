#!/bin/bash

set -ev
set +x

log_dir=${MONOPACKER_LOGS_DIR:-"/var/log/monopacker/scripts"}

function retry {
  set +e
  local n=0
  local max=5
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed" >&2
        sleep_time=$((2 ** n))
        echo "Sleeping $sleep_time seconds..." >&2
        sleep $sleep_time
        echo "Attempt $n/$max:" >&2
      else
        echo "Failed after $n attempts." >&2
        exit 1
      fi
    }
  done
  set -e
}

function log_execution() {
    mkdir -p ${log_dir} || true
    exec &> ${log_dir}/$(basename -a "${1}").log
}

set -x
