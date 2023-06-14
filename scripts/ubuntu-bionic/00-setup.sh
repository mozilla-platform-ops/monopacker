#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
for h in ${helpers_dir}/*.sh; do
    . $h;
done

echo "CLOUD=$CLOUD"
echo "NUM_LOOPBACK_AUDIO_DEVICES=$NUM_LOOPBACK_AUDIO_DEVICES"
echo "NUM_LOOPBACK_VIDEO_DEVICES=$NUM_LOOPBACK_VIDEO_DEVICES"

# Check if the BUILD_V4L2LOOPBACK variable is set. Currently
# we only set this for FirefoxCI.
if [[ -v $BUILD_V4L2LOOPBACK ]] ; then
echo "BUILD_V4L2LOOPBACK=$BUILD_V4L2LOOPBACK"
fi

# Check if the FIX_KERNEL_VERSION_MISMATCH variable is set.
# We only set it for Firefox CI Ubuntu 22.04+ machines.
if [[ -v $FIX_KERNEL_VERSION_MISMATCH ]] ; then
echo "FIX_KERNEL_VERSION_MISMATCH=$FIX_KERNEL_VERSION_MISMATCH"
fi

# Look at the given inputs and see if we can even do this.
fail() {
    echo "${@}"
    exit 1
}

case $CLOUD in
    google)
        case $NUM_LOOPBACK_AUDIO_DEVICES in
            0) SETUP_SND_ALOOP=false ;;
            32) SETUP_SND_ALOOP=true ;;
            *) fail "GCP supports only 0 or 32 loopback audio devices."
        esac
        case $NUM_LOOPBACK_VIDEO_DEVICES in
            0) SETUP_V4L2LOOPBACK=false ;;
            *) SETUP_V4L2LOOPBACK=true ;;
        esac
        ;;
    aws)
        case $NUM_LOOPBACK_AUDIO_DEVICES in
            0) SETUP_SND_ALOOP=false ;;
            *) SETUP_SND_ALOOP=true ;;
        esac
        case $NUM_LOOPBACK_VIDEO_DEVICES in
            0) SETUP_V4L2LOOPBACK=false ;;
            *) SETUP_V4L2LOOPBACK=true ;;
        esac
        ;;
    azure)
        case $NUM_LOOPBACK_AUDIO_DEVICES in
            0) SETUP_SND_ALOOP=false ;;
            *) fail "Azure does not support loopback audio (see ubuntu-bionic README)" ;;
        esac
        case $NUM_LOOPBACK_VIDEO_DEVICES in
            0) SETUP_V4L2LOOPBACK=false ;;
            *) fail "Azure does not support loopback video (see ubuntu-bionic README)" ;;
        esac
        ;;
    *) fail "Unknown CLOUD $CLOUD" ;;
esac

# Results (used by subsequent scripts, hence putting them in helpers_dir)
echo "SETUP_SND_ALOOP=$SETUP_SND_ALOOP" | tee -a ${helpers_dir}/kernel-inputs.sh
echo "SETUP_V4L2LOOPBACK=$SETUP_V4L2LOOPBACK" | tee -a ${helpers_dir}/kernel-inputs.sh
