#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# Needed for performance counters to be available when using docker-worker
# disableSeccomp capability - see:
#   * https://github.com/taskcluster/taskcluster/pull/5800
#
# TODO: This should be removed when docker itself supports capability
# CAP_PERFMON and docker-worker has been updated to use it. See
# https://github.com/taskcluster/taskcluster/pull/5800#issuecomment-1330635417
# for details.
if [ -n "${PERF_EVENT_PARANOID_VALUE}" ]; then
  echo "${PERF_EVENT_PARANOID_VALUE}" | sudo tee /proc/sys/kernel/perf_event_paranoid
fi
