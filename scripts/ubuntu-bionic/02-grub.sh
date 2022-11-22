#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# GRUB
# adapted from https://bgstack15.wordpress.com/2018/05/02/update-etc-default-grub-programmatically/
GRUB_INFILE=/etc/default/grub

cp -p "${GRUB_INFILE}" "${GRUB_INFILE}.orig"

TMP_DIR="$(mktemp -d)"
TMP_FILE="$(TMPDIR="${TMP_DIR}" mktemp)"

# clean up temp file if necessary
test ! -e "${TMP_FILE}" && { touch "${TMP_FILE}" || exit 1 ; }
cat "${GRUB_INFILE}" > "${TMP_FILE}"

add_value_to_grub_line "${TMP_FILE}" "GRUB_CMDLINE_LINUX" "debug g"
add_value_to_grub_line "${TMP_FILE}" "GRUB_CMDLINE_LINUX_DEFAULT" "splash"
remove_value_from_grub_line "${TMP_FILE}" "GRUB_CMDLINE_LINUX_DEFAULT" "quiet"

update_grub_if_changed "${GRUB_INFILE}" "${TMP_FILE}"

# show final results
cat "${GRUB_INFILE}"
rm -rf "${TMP_DIR}" 2>/dev/null

# FIXME does not exist?
# shown here https://launchpad.net/ubuntu/+source/linux-signed/4.15.0-58.64
# retry apt-get install -y linux-image-$KERNEL_VERSION-dbgsym

# Shutdown and wait forever; packer will consider this script to have finished and
# start on the next script when it reconnects
shutdown -r now
while true; do sleep 1; done
