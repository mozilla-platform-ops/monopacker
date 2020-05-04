#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

echo "start kernel: $(uname -r)"

# prevents interactive installation
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
export DEBIAN_FRONTEND=noninteractive

# Update kernel
# We install the generic kernel because it has the V4L2 driver
KERNEL_NOVARIANT_VERSION=5.3.0-1017
KERNEL_VERSION=$KERNEL_NOVARIANT_VERSION-aws

# testing updating AWS kernel and adding extras package
# KERNEL_VERSION=4.15.0-1045-aws

retry apt update

# Upgrade to the latest kernel from the base image. If not, a bug in apt-get remove
# may install a newer kernel after we remove the old one
retry apt install -y unattended-upgrades
unattended-upgrade

# uninstall old kernel
apt remove -y $(ls -1 /boot/vmlinuz-*{aws,gcp} | sed -e 's,/boot/vmlinuz,linux-image,')
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

# install crash debug tools
retry apt install -y linux-crashdump kmod

# kernel debug
grep 'USE_KDUMP' /etc/default/kdump-tools
echo 'USE_KDUMP=1' >> /etc/default/kdump-tools

# Ensure that we load AWS / Nitro modules
echo "ena" | tee --append /etc/modules
echo "nvme" | tee --append /etc/modules

# At this point we need a reboot to handle the kernel update
# this is handled in the grub script
