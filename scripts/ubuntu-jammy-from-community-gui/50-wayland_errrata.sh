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

cat > /etc/dconf/profile/user << EOF
user-db:user
system-db:local
EOF

mkdir /etc/dconf/db/local.d/
# dconf user settings
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
# gdm wait service file
#

# This hack is required because without we end up in a situation where the
# wayland seat is in a weird state and consequences are:
#    - either x11 session
#    - either xwayland fallback
#    - either wayland but with missing keyboard capability that breaks
#        things including copy/paste

mkdir -p /etc/systemd/system/gdm.service.d/
cat > /etc/systemd/system/gdm.service.d/gdm-wait.conf << EOF
[Unit]
Description=Extra 30s wait

[Service]
ExecStartPre=/bin/sleep 30
EOF


#
# extra packages
#

# ttf-mscorefonts-installer is part of ubuntu-restricted-extras, accept license
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

# install stuff
apt install -y ubuntu-restricted-extras wl-clipboard


#
# write mutter's monitors.xml
#

cat > /etc/xdg/monitors.xml << EOF
<monitors version="2">
  <configuration>
    <logicalmonitor>
      <x>0</x>
      <y>0</y>
      <scale>1</scale>
      <primary>yes</primary>
      <monitor>
        <monitorspec>
          <connector>Virtual-1</connector>
          <vendor>unknown</vendor>
          <product>unknown</product>
          <serial>unknown</serial>
        </monitorspec>
        <mode>
          <width>1920</width>
          <height>1080</height>
          <rate>60.000</rate>
        </mode>
      </monitor>
    </logicalmonitor>
  </configuration>
</monitors>
EOF
