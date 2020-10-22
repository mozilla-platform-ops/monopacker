#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

KERNEL_VERSION=$(uname -r)
echo "KERNEL_VERSION=$KERNEL_VERSION"
echo "OLD_KERNEL=$OLD_KERNEL"

# prevents interactive installation
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
export DEBIAN_FRONTEND=noninteractive

if $OLD_KERNEL; then
    KERNEL_NOVARIANT_VERSION=5.4.0-1024
    KERNEL_VERSION=$KERNEL_NOVARIANT_VERSION-aws

    retry apt update

    # Upgrade to the latest kernel from the base image. If not, a bug in apt-get remove
    # may install a newer kernel after we remove the old one
    retry apt install -y unattended-upgrades
    unattended-upgrade

    # uninstall all kernels
    apt remove -y $(dpkg-query  -f '${binary:Package}\n' -W | grep 'linux-\(image\|modules\|headers\)')
    apt autoremove -y --purge

    # necessary for linux-modules-extra
    retry apt install -y crda wireless-crda

    # install new kernel
    pushd /var/kernel
    dpkg -i --force-confnew linux-modules-$KERNEL_VERSION*.deb
    dpkg -i --force-confnew linux-image-$KERNEL_VERSION*.deb
    dpkg -i --force-confnew linux-modules-extra-$KERNEL_VERSION*.deb
    dpkg -i --force-confnew linux-aws-*headers-$KERNEL_NOVARIANT_VERSION*.deb
    dpkg -i --force-confnew linux-headers-$KERNEL_VERSION*.deb
    dpkg -i --force-confnew linux-buildinfo-$KERNEL_VERSION*.deb
    popd

    # Avoid kernel upgrades
    echo linux-image-$KERNEL_VERSION hold | dpkg --set-selections
    echo linux-modules-$KERNEL_VERSION hold | dpkg --set-selections
    echo linux-modules-extra-$KERNEL_VERSION hold | dpkg --set-selections
    echo linux-aws-headers-$KERNEL_NOVARIANT_VERSION hold | dpkg --set-selections
    echo linux-headers-$KERNEL_VERSION hold | dpkg --set-selections
    echo linux-buildinfo-$KERNEL_VERSION hold | dpkg --set-selections
    echo linux-image-aws hold | dpkg --set-selections
    echo linux-aws hold | dpkg --set-selections

    # Double-check that only the desired kernel is installed
    installed=$(ls -1 /boot/vmlinu*)
    if [ "$installed" != "/boot/vmlinuz-$KERNEL_VERSION" ]; then
        echo "Failed to limit to a single kernel:"
        ls /boot
        exit 1
    fi
fi

# install crash debug tools
retry apt install -y linux-crashdump kmod

# kernel debug
grep 'USE_KDUMP' /etc/default/kdump-tools
echo 'USE_KDUMP=1' >> /etc/default/kdump-tools

# Ensure that we load AWS / Nitro modules
if [ "$CLOUD" = "aws" ]; then
    echo "ena" | tee --append /etc/modules
    echo "nvme" | tee --append /etc/modules
fi

# At this point we need a reboot to handle the kernel update
# this is handled in the grub script