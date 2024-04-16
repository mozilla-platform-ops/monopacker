#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

# see https://github.com/mozilla-platform-ops/monopacker/issues/138


#
# install tools
#

# used to modify specific blocks in .conf files
apt install -y crudini


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

crudini  --set /etc/gdm3/custom.conf daemon XorgEnable 'false'

# verify/test
cat /etc/gdm3/custom.conf
echo "----"
grep 'XorgEnable' /etc/gdm3/custom.conf
grep 'XorgEnable' /etc/gdm3/custom.conf | grep false

#
# gdm3 service file
#

# copy /lib/systemd/system/gdm3.service to /etc/systemd/system and change its 
# ExecStartPre to `/bin/sleep 15`

# NOTES: this is a hack. alissy is working on a better solution.

cp /lib/systemd/system/gdm3.service /etc/systemd/system/gdm3.service
crudini --set /etc/systemd/system/gdm3.service Service ExecStartPre '/bin/sleep 15'

# verify/test
cat /etc/systemd/system/gdm3.service
echo "----"
grep 'ExecStartPre' /etc/systemd/system/gdm3.service
grep 'ExecStartPre' /etc/systemd/system/gdm3.service | grep 'sleep 15'

#
# extra packages
#

# ttf-mscorefonts-installer is part of ubuntu-restricted-extras, accept license
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

# install stuff
apt install -y ubuntu-restricted-extras wl-clipboard


#
# TODO: generate mutter's monitors.xml
#

# config TBD