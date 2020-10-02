#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

KERNEL_VERSION=$(uname -r)
echo "KERNEL_VERSION=$KERNEL_VERSION"
echo "REBUILD_KERNEL=$REBUILD_KERNEL"
echo "SETUP_SND_ALOOP=$SETUP_SND_ALOOP"
echo "BUILD_V4L2LOOPBACK=$BUILD_V4L2LOOPBACK"

# prevents interactive installation
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
export DEBIAN_FRONTEND=noninteractive

# TODO: re-add the `hold` stuff that was deleted

if $REBUILD_KERNEL; then
    # set up to access the source debs
    sed -i -e 's/# deb-src/deb-src/' /etc/apt/sources.list
    apt-get update

    # save the set of selected packages, for later restoration
    dpkg --get-selections > /root/Packages

    # get the kernel headers (for Module.symvers)
    apt-get install -y linux-headers-$(uname -r)

    # get the requirements to build the kernel
    apt-get -y build-dep linux linux-image-$(uname -r)
    # TODO: does autoremove remove these? mk-build-deps?
    # TODO: or dpkg --get-selections > ~/Package.list / --set-selections?

    mkdir -p /usr/src/kernel-build
    pushd /usr/src/kernel-build

    # get the linux-image source
    # (NOTE: this appears not to actually contain source for the gcp variant)
    apt-get -y source linux-image-$(uname -r)
    cd linux-*/

    # https://yoursunny.com/t/2018/one-kernel-module/

    # compile a new config by concatenating the desired changes to the .config
    # and letting `make oldconfig` sort it out.  NOTE: none of these changes can
    # alter what is built in the kernel itself, as we do not install the new
    # image!
    cat /boot/config-$(uname -r) > .config
    cp /usr/src/linux-headers-$(uname -r)/Module.symvers .

    if $BUILD_V4L2LOOPBACK; then
        (
            echo CONFIG_MEDIA_CAMERA_SUPPORT=y
            echo CONFIG_VIDEO_DEV=m
            echo CONFIG_VIDEO_V4L2=m
            echo CONFIG_USB_GSPCA=m
            echo CONFIG_VIDEOBUF2_CORE=m
            echo CONFIG_VIDEOBUF2_V4L2=m
            echo CONFIG_VIDEOBUF2_MEMOPS=m
            echo CONFIG_VIDEOBUF2_VMALLOC=m
            echo CONFIG_MEDIA_SUBDRV_AUTOSELECT=y
        ) >> .config
    fi

    if $BUILD_SND_ALOOP; then
        (
            echo CONFIG_SOUND=m
            echo CONFIG_SND=m
            echo CONFIG_SND_TIMER=m
            echo CONFIG_SND_PCM=m
            echo CONFIG_SND_PCM_TIMER=y
            echo CONFIG_SND_DYNAMIC_MINORS=y
            echo CONFIG_SND_MAX_CARDS=$NUM_LOOPBACK_AUDIO_DEVICES
            echo CONFIG_SND_SUPPORT_OLD_API=y
            echo CONFIG_SND_PROC_FS=y
            echo CONFIG_SND_VERBOSE_PROCFS=y
            echo CONFIG_SND_DMA_SGBUF=y
            echo CONFIG_SND_DRIVERS=y
            echo CONFIG_SND_ALOOP=m
            echo CONFIG_SND_PCI=y
            echo CONFIG_SND_HDA_PREALLOC_SIZE=64
            echo CONFIG_SND_SPI=y
            echo CONFIG_SND_USB=y
            echo CONFIG_SND_X86=y
        ) >> .config
    fi

    # the 'yes ''` here selects the default for all previously-unset
    # configs uncovered by the above
    yes '' | make oldconfig

    # We just blindly build all modules becauase that's easier than predicting
    # exactly which need to be installed and it doesn't take too long.
    J=`getconf _NPROCESSORS_ONLN`
    make -j $J modules

    # modules_install requires the image be built first.
    make -j $J vmlinux

    # restore the selections.  This should make autoremove in the cleanup
    # script remove anything we've selected above
    dpkg --set-selections < /root/Packages

    popd
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
