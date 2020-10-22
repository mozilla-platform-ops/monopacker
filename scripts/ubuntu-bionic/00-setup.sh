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

# Look at the given inputs and see if we can even do this.
fail() {
    echo "${@}"
    exit 1
}

OLD_KERNEL=false
case $CLOUD in
    google)
        case $NUM_LOOPBACK_AUDIO_DEVICES in
            0) SETUP_SND_ALOOP=false ;;
            32) SETUP_SND_ALOOP=true ;;
            *) fail "GCP supports only 0 or 32 loopback audio devices."
        esac
        case $NUM_LOOPBACK_VIDEO_DEVICES in
            0) BUILD_V4L2LOOPBACK=false ;;
            *) BUILD_V4L2LOOPBACK=true ;;
        esac
        ;;
    aws)
        case $NUM_LOOPBACK_AUDIO_DEVICES in
            0) SETUP_SND_ALOOP=false ;;
            32) SETUP_SND_ALOOP=true ;;
            *) SETUP_SND_ALOOP=true OLD_KERNEL=true ;;
        esac
        case $NUM_LOOPBACK_VIDEO_DEVICES in
            0) BUILD_V4L2LOOPBACK=false ;;
            *) BUILD_V4L2LOOPBACK=true OLD_KERNEL=true ;;
        esac
        ;;
    azure)
        case $NUM_LOOPBACK_AUDIO_DEVICES in
            0) SETUP_SND_ALOOP=false ;;
            *) fail "Azure does not support loopback audio (see ubuntu-bionic README)" ;;
        esac
        case $NUM_LOOPBACK_VIDEO_DEVICES in
            0) BUILD_V4L2LOOPBACK=false ;;
            *) fail "Azure does not support loopback video (see ubuntu-bionic README)" ;;
        esac
        ;;
    *) fail "Unknown CLOUD $CLOUD" ;;
esac

# Results (used by subsequent scripts, hence putting them in helpers_dir)
echo "OLD_KERNEL=$OLD_KERNEL" | tee ${helpers_dir}/kernel-inputs.sh
echo "SETUP_SND_ALOOP=$SETUP_SND_ALOOP" | tee -a ${helpers_dir}/kernel-inputs.sh
echo "BUILD_V4L2LOOPBACK=$BUILD_V4L2LOOPBACK" | tee -a ${helpers_dir}/kernel-inputs.sh
