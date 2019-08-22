#!/bin/bash

set -ex
set +v

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

# Adapted from https://bgstack15.wordpress.com/2018/05/02/update-etc-default-grub-programmatically/
function update_grub_if_changed() {
   # call: update_grub_if_changed "${GRUB_INFILE}" "${TMP_FILE}"

   local infile="${1}"
   local tmpfile="${2}"

   # determine if changes were made to the file
   if diff -q "${infile}" "${tmpfile}" 2>&1 | grep -qiE 'differ' ;
   then
      # changes were made
      cp -p "${tmpfile}" "${infile}"
      # writes from /etc/default/grub
      grub-mkconfig -o "/boot/grub/grub.cfg"
   else
      # no changes
      :
   fi

}

function add_value_to_grub_line() {
   # call: add_value_to_grub_line "${TMP_FILE}" "GRUB_CMDLINE_LINUX" "quiet"

   local infile="${1}"
   local thisvar="${2}"
   local thisvalue="${3}"

   sed -i -r -e "/^${thisvar}=/{ /${thisvalue}/! { s/\"\s*\$/${thisvalue}\"/; } ; }" "${infile}"

}

function remove_value_from_grub_line() {
   # call: remove_value_from_grub_line "${TMP_FILE}" "GRUB_CMDLINE_LINUX" "quiet"

   local infile="${1}"
   local thisvar="${2}"
   local thisvalue="${3}"

   sed -i -r -e "/^${thisvar}=/{ /${thisvalue}/ { s/\s*${thisvalue}//; } ; }" "${infile}"

}

set -v
