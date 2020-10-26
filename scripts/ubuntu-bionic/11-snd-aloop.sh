#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

if ! $SETUP_SND_ALOOP; then
    echo "Skiping snd-aloop"
    exit
fi

# Configure audio loopback devices, with options enable=1,1,1...,1 index = 0,1,...,N
i=0
enable=''
index=''
while [ $i -lt $NUM_LOOPBACK_AUDIO_DEVICES ]; do
    enable="$enable,1"
    index="$index,$i"
    i=$((i + 1))
done
# slice off the leading `,` in each variable
enable=${enable:1}
index=${index:1}

echo "options snd-aloop enable=$enable index=$index" > /etc/modprobe.d/snd-aloop.conf
echo "snd-aloop" | tee --append /etc/modules

# Test
modprobe snd-aloop
lsmod | grep snd_aloop
test -e /dev/snd/controlC$((NUM_LOOPBACK_AUDIO_DEVICES - 1))
