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

* Sets up the kernel for the desired loopback audio and video devices.  Some combinations require recompiling the kernel, and in some cases (GCP) this is not currently supported.
  This installs a specific version of the v4l2oopback driver, different from the one provided in upstream Ubuntu packages.
* Installs some basic packages required to build things (build-essentials, gnupg, curl)
* Installs some "misc packages"; see `30-packages.sh` for the list.  Generally these are small and fine to install unconditionally.
* Installs `python-statsd` for reasons that are lost to history
* Installs a fix for docker networking (https://github.com/moby/libnetwork/issues/1090)

## Notes

The kernel variants are quite different, even at the level of how they are packaged.
As we currently only need to recompile on AWS, recompilation is not supported for the GCP variant.
If this becomes necessary, some work will be required to figure out how to rebuild the GCP variant.

No support for devices is provided for Azure.
This merely requires investigation - snd-aloop may already be built into the Azure kernel variant.
