#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# see https://github.com/mozilla-platform-ops/monopacker/issues/138


#
# dconf settings
#

# /etc/dconf/profile/user should have (no leading spaces):
#
#   user-db:user
#   system-db:local
cat > /etc/dconf/profile/user << EOF
user-db:user
system-db:local
EOF

# /etc/dconf/db/local.d/00-tc-gnome-settings should have (no leading spaces): 
#
# # /org/gnome/desktop/session/idle-delay
# [org/gnome/desktop/session]
# idle-delay=uint32 0
#
# # /org/gnome/desktop/lockdown/disable-lock-screen
# [org/gnome/desktop/lockdown]
# disable-lock-screen=true
mkdir /etc/dconf/db/local.d/
cat > /etc/dconf/db/local.d/00-tc-gnome-settings << EOF
# /org/gnome/desktop/session/idle-delay
[org/gnome/desktop/session]
idle-delay=uint32 0

# /org/gnome/desktop/lockdown/disable-lock-screen
[org/gnome/desktop/lockdown]
disable-lock-screen=true
EOF

# make dbus read the new configuration
sudo dconf update

# test
ls -hal /etc/dconf/db/


#
# gdm3 settings  
#

# in [daemon] block of /etc/gdm3/custom.conf we need:
#
# XorgEnable=false

# TODO: how to do this? augeas or crudini?
#  - https://superuser.com/questions/155418/is-there-a-program-script-to-modify-conf-files

apt install -y crudini
crudini  --set ./custom.conf daemon XorgEnable 'false'

cat /etc/gdm3/custom.conf
grep 'XorgEnable' /etc/gdm3/custom.conf


#
# gdm3 service file
#

# copy /lib/systemd/system/gdm3.service to /etc/systemd/system and change its 
# ExecStartPre to `/bin/sleep 30`

cp /lib/systemd/system/gdm3.service /etc/systemd/system/gdm3.service
crudini --set /etc/systemd/system/gdm3.service Service ExecStartPre '/bin/sleep 30'

cat /etc/systemd/system/gdm3.service
grep 'ExecStartPre' /etc/systemd/system/gdm3.service


#
# extra packages
#

apt install -y ubuntu-restricted-extras wl-clipboard


#
# TODO: generate mutter's monitors.xml (only if needed)
#
