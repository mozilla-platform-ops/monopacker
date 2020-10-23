# ubuntu-bionic

This scripts directory sets up an Ubuntu (Bionic) image.

## Inputs

The base image must be a Bionic image produced by Canonical.

* `CLOUD` - the cloud being built for (`azure`, `aws`, or `google`)
* `NUM_LOOPBACK_AUDIO_DEVICES` - number of snd-aloop devices (for docker-worker's loopbackAudio support) to support (0 to disable)
* `NUM_LOOPBACK_VIDEO_DEVICES` - number of v4l2loopback devices (for docker-worker's loopbackVideo support) to support (0 to disable)
* `V4L2LOOPBACK_VERSION` - version of the v4l2loopback module to install (default in the script)

Note that the kernel version used is that of the base image.

## Behaviors

* Sets up kernel modules for the desired loopback audio and video devices. Not all combinations are supported.
* Installs a specific version of the v4l2oopback driver, different from the one provided in upstream Ubuntu packages.
* Installs some basic packages required to build things (build-essentials, gnupg, curl)
* Installs some "misc packages"; see `30-packages.sh` for the list.  Generally these are small and fine to install unconditionally.
* Installs `python-statsd` for reasons that are lost to history
* Installs a fix for docker networking (https://github.com/moby/libnetwork/issues/1090)

## Notes

The kernel variants are quite different, even at the level of how they are packaged. We currently just use whatever
kernel comes on the image but we could support rebuilding the kernel in the future if needed. See taskcluster/monopacker#88 and 
taskcluster/taskcluster#3574 for more details about the why/how/why-not of what we do currently. tl;dr gcp supports snd-aloop
out of the box but aws does not. Since we aren't building aws images in here for firefox-ci we're just going
to avoid the issue. If you wish to fix a currently existing firefox-ci image your best bet is to just do it manually by
spinning up an image, making a change, and building a new image from it in the aws console.

No support for devices is provided for Azure.
This merely requires investigation - snd-aloop may already be built into the Azure kernel variant.